
package kg::Elections::Model::Election;

use 5.14.0;
use warnings;

use Carp qw/croak/;
use Data::UUID;
use Digest::SHA1  qw(sha1_base64);

use kg::Elections::Utils qw/get_dbh/;
use kg::Elections::Model::Vote;

use Class::Accessor::Lite(
    rw  => [
        'id',  # the db primary key
		'xid', # a uuid
        'name',
        'election_date',
        'num_allowed',
        'deleted',
    ],
);

sub new {
	my ($class, %p) = @_;

	$p{xid} ||= Data::UUID->new->create_str();

	return bless \%p, $class;
}

sub save {
    my ($self) = @_;

    if ($self->id) {
        return $self->update;
    }

    my $sql = <<EOL;
    INSERT INTO elections (
        name,
		xid,
        election_date,
        num_allowed,
        deleted
    )
    VALUES (?,?,?,?,?);
EOL

    my $deleted = $self->deleted // 0;

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute((map { $self->$_ } qw/name xid election_date num_allowed /), $deleted);

    $self->id($dbh->sqlite_last_insert_rowid);
}

sub update {
    my ($self) = @_;

    my $sql = <<EOL;
        UPDATE elections SET
            name = ?,
            election_date = ?,
            num_allowed = ?,
            deleted = ?
        WHERE id = ?
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(map { $self->$_ } qw/name election_date num_allowed deleted id/);
}

sub load {
    my ($class, $id, %p) = @_;

    croak "missing id in call to $class->load" unless $id;

    my $sql = 'SELECT * FROM elections WHERE id = ?';

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($id);
    if (my $row = $sth->fetchrow_hashref) {
        return bless $row, $class;
    } else {
        return;
    }
}

sub load_by_xid {
    my ($class, $xid) = @_;

    croak "missing id in call to $class->load" unless $xid;

    my $sql = 'SELECT * FROM elections WHERE xid = ?';

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($xid);
    if (my $row = $sth->fetchrow_hashref) {
        return bless $row, $class;
    } else {
        return;
    }
}

sub record_vote {
    my ($self, %p) = @_;

    my $voter_str = $p{voter} or croak "voter identifier required in record_vote";
    my $vote_str = $p{vote} or croak "missing vote";

    my $votes_recorded = $self->get_num_votes_recorded;

    if ($votes_recorded >= $self->num_allowed) {
        croak "no more votes allowed for '".$self->name."' on ".$self->election_date;
    }

    my $vote_obj = kg::Elections::Model::Vote->new(
        election_id => $self->id,
        voter => $voter_str,
        vote => $vote_str,
    );
    $vote_obj->save;

    return wantarray ? ($voter_str, $vote_obj->id) : $voter_str;
}

sub get_num_votes_recorded {
    my ($self) = @_;

    return kg::Elections::Model::Vote->num_votes_for_election($self->id);
}

sub get_all_votes_recorded {
    my ($self) = @_;

    return kg::Elections::Model::Vote->votes_for_election($self->id);
}

sub create_table {

    my $dbh = get_dbh();

    my $sql = <<EOL;
CREATE TABLE elections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	xid VARCHAR(36),
    name VARCHAR(255) NOT NULL,
    election_date DATE(255) NOT NULL,
    num_allowed INT NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT 0
);
EOL
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    $sql = <<EOL;
CREATE UNIQUE INDEX election_name_date 
ON elections (name, election_date);
EOL
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sql = <<EOL;
CREATE INDEX election_xid
ON elections (xid);
EOL
    $sth = $dbh->prepare($sql);
    $sth->execute;
}
1;

