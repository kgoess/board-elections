
use strict;
use Test::More tests => 12;
use Test::Exception;

use kg::Elections::Model::Election;
use kg::Elections::Model::Vote;


$ENV{SQLITE_FILE} = 'elections-test';
unlink $ENV{SQLITE_FILE};

$ENV{DBI_PRINT_ERROR} = 0;

kg::Elections::Model::Election->create_table;
kg::Elections::Model::Vote->create_table;

test_elections_crud();
test_votes_crud();
test_record_vote();

sub test_elections_crud {
    my $e = kg::Elections::Model::Election->new(
        name => 'test election',
        election_date => '2020-05-01',
        num_allowed => 5,
    );

    $e->save;

    my $e2 = kg::Elections::Model::Election->load($e->id);

    is $e2->name, 'test election';
    is $e2->election_date, '2020-05-01';

    my $uuid = Data::UUID->new;

    ok $uuid->from_string($e2->xid);

    $e2->name('test XXXX');
    $e2->save;

    my $e3 = kg::Elections::Model::Election->load($e->id);
    is $e3->name, 'test XXXX';

    my $e4 = kg::Elections::Model::Election->load_by_xid($e3->xid);
    is $e4->name, 'test XXXX';
}

sub test_votes_crud {

    my $v = kg::Elections::Model::Vote->new(
        election_id => 123,
        voter_sha1 => 'alice',
        vote => 'yes'
    );

    $v->save;

    my $v2 = kg::Elections::Model::Vote->load($v->id);

    is $v2->voter_sha1, 'alice';
    is $v2->vote, 'yes';
}

sub test_record_vote {
    my $e = kg::Elections::Model::Election->new(
        name => 'test election',
        election_date => '2020-05-01',
        num_allowed => 2,
    );
    $e->save;


    my ($sha1, $vote_id) = $e->record_vote(
        election_id => $e->id,
        voter_name => 'alice',
        vote => 'yes'
    );
    my $v = kg::Elections::Model::Vote->load($vote_id);
    is $v->vote, 'yes';

    throws_ok {
        $e->record_vote(
            election_id => $e->id,
            voter_name => 'alice',
            vote => 'yes'
        );
    } qr/UNIQUE constraint failed: votes.election_id, votes.voter_sha1/;

    ($sha1, $vote_id) = $e->record_vote(
        election_id => $e->id,
        voter_name => 'bob',
        vote => 'no'
    );

    $v = kg::Elections::Model::Vote->load($vote_id);
    is $v->vote, 'no';

    is $e->get_num_votes_recorded, 2;

    throws_ok {
        $e->record_vote(
            election_id => $e->id,
            voter_name => 'alice',
            vote => 'yes'
        );
    } qr/no more votes allowed for 'test election' on 2020-05-01/;
}

