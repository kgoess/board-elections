package kg::Elections::View;

use strict;
use warnings;

use Carp qw/croak/;
use Data::Dump qw/dump/;
use Data::UUID;
use Template;
use JSON();

use kg::Elections::Model::Election;
use kg::Elections::Model::Vote;

# when either kg::Elections::Controller::ModPerl or kg::Elections::Controller::CGI loads
# this module, Perl calls this import() function and we set the location
# of the uri_for implementation
sub import {
    my ($class, $location) = @_;

    return unless $location;

    no warnings 'redefine';
    my $uri_for_implementation = join '::', $location, 'uri_for';
    *uri_for = \&{$uri_for_implementation};

    my $static_uri_for_implementation = join '::', $location, 'static_uri_for';
    *static_uri_for = \&{$static_uri_for_implementation};
}
#sub uri_for { ... }
#sub static_uri_for { ... }

sub create_election {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'create-election.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'BACDS',
        errors => $p{errors},

    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub election_created {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'election-created.tt';

    my $voting_url = uri_for(
        with_host => 1,
        path => '/vote-start',
        xid => $p{election}->xid,
    );

    my $vars = get_vars(
        \%p,
        organization_name => 'BACDS',
        errors => $p{errors},
        name => $p{election}->name,
        election_date => $p{election}->election_date,
        num_voters => $p{election}->num_allowed,
        voting_url => $voting_url,

    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub vote_start {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'vote-start.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'BACDS',
        errors => $p{errors},
        name => $p{election}->name,
        election_date => $p{election}->election_date,
        election_name => $p{election}->name,
        #num_voters => $p{election}->num_allowed,
        election_xid => $p{election}->xid,
		voter => Data::UUID->new->create_str(),


    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub watch_election {
    my ($class, %p) = @_;

    my $tt = get_tt();

	my @votes;
	if ($p{votes}) {
		@votes = @{$p{votes}};
		@votes = sort { $a->vote cmp $b->vote } @votes;
	}

    my $template = 'watch-election.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'BACDS',
        errors => $p{errors},
        name => $p{election}->name,
        election_date => $p{election}->election_date,
        election_name => $p{election}->name,
        #num_voters => $p{election}->num_allowed,
        election_xid => $p{election}->xid,
		votes_recorded => $p{votes_recorded},
		num_allowed => $p{num_allowed},
		(@votes ? (votes => \@votes) : ()),
		voter => $p{voter},
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}


my $_tt;
sub get_tt {

    my $config = {
        INCLUDE_PATH => ($ENV{TT_INCLUDE_PATH} || './templates'),
        PRE_PROCESS => 'header.tt', # add config as arrayref with organization_name?
        POST_PROCESS => 'footer.tt',
    };

    $_tt ||= Template->new($config);
    return $_tt;
}


sub get_vars {
    my $p = shift;
    my %vars = @_;

    return {
        uri_for        => \&uri_for,
        static_uri_for => \&static_uri_for,
        to_json => \&to_json,
        %vars,
    };
}


1;
