
package kg::Elections::Model::Election;

use 5.14.0;
use warnings;

use Carp qw/croak/;
use Digest::SHA1  qw(sha1_base64);

use kg::Elections::Utils qw/get_dbh/;
use kg::Elections::Model::Vote;

use Class::Accessor::Lite(
    new => 1,
    rw  => [
        'id',  # the db primary key
        'name',
        'election_date',
        'num_allowed',
        'deleted',
    ],
);

sub save {
    my ($self) = @_;

    if ($self->id) {
        return $self->update;
    }

    my $sql = <<EOL;
    INSERT INTO elections (
        name,
        election_date,
        num_allowed,
        deleted
    )
    VALUES (?,?,?,?);
EOL

    my $deleted = $self->deleted // 0;

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute((map { $self->$_ } qw/name election_date num_allowed /), $deleted);

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

sub record_vote {
    my ($self, %p) = @_;

    my $election_id = $p{election_id} or croak "missing election_id";
    my $voter_name = $p{voter_name};
    my $voter_sha1 = $p{voter_sha1};
    ($voter_name || $voter_sha1) or croak "either voter_name or voter_sha1 required in record_vote";
    my $vote = $p{vote} or croak "missing vote";

    $voter_sha1 ||= sha1_base64($voter_name);

    my $election = kg::Elections::Model::Election->load($election_id)
        or croak "no election found for id $election_id";

    my $votes_recorded = $self->get_num_votes_recorded;

    if ($votes_recorded >= $election->num_allowed) {
        croak "no more votes allowed for '".$election->name."' on ".$election->election_date;
    }

    my $vote_obj = kg::Elections::Model::Vote->new(
        election_id => $election_id,
        voter_sha1 => $voter_sha1,
        vote => $vote,
    );
    $vote_obj->save;

    return wantarray ? ($voter_sha1, $vote_obj->id) : $voter_sha1;
}

sub get_num_votes_recorded {
    my ($self) = @_;

    return kg::Elections::Model::Vote->votes_for_election($self->id);
}

sub create_table {

    my $dbh = get_dbh();

    my $sql = <<EOL;
CREATE TABLE elections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
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
}
1;

