
use strict;
use warnings;

use Data::Dump qw/dump/;

use Test::More tests => 3;

use kg::Elections::Controller;
use kg::Elections::Controller::CGI;

{
package MockRequest;
    sub new {
        my ($class, %p) = @_;

        return bless \%p, $class;
    }
    sub param {
        my ($self, $name) = @_;
        return $self->{$name};
    }
    no warnings 'once';
    *url_param = \&param;
}


$ENV{SQLITE_FILE} = 'elections-test';
$ENV{ELECTIONS_URI_BASE} = '/elections';
$ENV{ELECTIONS_STATIC_URI_BASE} = '/elections-static';
unlink $ENV{SQLITE_FILE};

kg::Elections::Model::Election->create_table;
kg::Elections::Model::Vote->create_table;


test_create_election();

sub test_create_election {

    my ($result, $request);

    $request = MockRequest->new();

    $result = kg::Elections::Controller->create_election(
        method => 'GET',
        request => $request,
        uri_for => \&kg::Elections::Controller::CGI::uri_for,
    );
    is $result->{action}, 'display';

    $request = MockRequest->new(
        name => 'test election 1',
        'election-date' => '2020-05-02',
        'num-allowed' => 6,
    );
    $result = kg::Elections::Controller->create_election(
        method => 'POST',
        request => $request,
        uri_for => \&kg::Elections::Controller::CGI::uri_for,
    );
    is $result->{action}, 'redirect' or dump $result;

	my $election = $result->{debug}{election};
	my $xid = $election->xid;
    is $result->{headers}{Location}, "/elections?path=/election-created&xid=$xid";
}

