
package kg::Elections::Model::Vote;

use 5.14.0;
use warnings;

use Carp qw/croak/;

use kg::Elections::Utils qw/get_dbh/;

use Class::Accessor::Lite(
    new => 1,
    rw  => [
        'id',  # the db primary key
        'election_id',
        'voter',
        'vote',
    ],
);

sub save {
    my ($self) = @_;

    if ($self->id) {
        return $self->update;
    }

    my $sql = <<EOL;
    INSERT INTO votes (
        election_id,
        voter,
        vote
    )
    VALUES (?,?,?);
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(map { $self->$_ } qw/election_id voter vote /);

    $self->id($dbh->sqlite_last_insert_rowid);
}

sub update {
    my ($self) = @_;

    croak "there is no update for votes, they are permanent";

}

sub load {
    my ($class, $id, %p) = @_;

    croak "missing id in call to $class->load" unless $id;

    my $sql = 'SELECT * FROM votes WHERE id = ?';

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($id);
    if (my $row = $sth->fetchrow_hashref) {
        return bless $row, $class;
    } else {
        return;
    }
}

sub num_votes_for_election {
    my ($class, $election_id) = @_;

    $election_id or croak "missing election_id in call to num_votes_for_election";

    my $dbh = get_dbh();

    my $sql = <<EOL;
SELECT COUNT(*) FROM votes
WHERE election_id = ?
EOL

    my $sth = $dbh->prepare($sql);
    $sth->execute($election_id);
    return $sth->fetchrow_arrayref->[0];
}

sub votes_for_election {
    my ($class, $election_id) = @_;

    $election_id or croak "missing election_id in call to votes_for_election";

    my $dbh = get_dbh();

    my $sql = <<EOL;
SELECT * FROM votes
WHERE election_id = ?
EOL

    my $sth = $dbh->prepare($sql);
    $sth->execute($election_id);
    my @rc;
    while (my $row = $sth->fetchrow_hashref) {
        push @rc, $class->new($row);
    }
    return @rc;
}


sub create_table {

    my $dbh = get_dbh();

    my $sql = <<EOL;
CREATE TABLE votes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    election_id INTEGER NOT NULL,
    voter VARCHAR(255) NOT NULL,
    vote VARCHAR(255) NOT NULL
);
EOL
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    $sql = <<EOL;
CREATE UNIQUE INDEX votes_election_voter
ON votes (election_id, voter);
EOL
    $sth = $dbh->prepare($sql);
    $sth->execute;

}
1;

