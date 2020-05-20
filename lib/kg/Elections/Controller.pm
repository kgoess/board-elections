package kg::Elections::Controller;

use strict;
use warnings;

use Carp qw/croak/;
use CGI::Cookie;
use Data::Dump qw/dump/;
use Digest::SHA1  qw(sha1_base64);

#use kg::Elections::Logger;
#use kg::Elections::Model::Event;
#use kg::Elections::Model::Person;
#use kg::Elections::Model::PersonEventMap;
#use kg::Elections::Utils qw/uri_escape/;

my %handler_for_path = (
    ''                  => sub { shift->main_page(@_) },
    '/'                 => sub { shift->main_page(@_) },
    '/create-election'  => sub { shift->create_election(@_) },
    '/election-created' => sub { shift->election_created(@_) },
    '/vote-start'       => sub { shift->vote_start(@_) },
);

sub go {
    my ($class, %p) = @_;

    if (my $handler = $handler_for_path{ $p{path_info} }) {
        return $handler->($class, %p),
    } else {
        die "missing handler for '$p{path_info}'";
    }
}

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

sub create_election {
    my ($class, %p) = @_;

    if ($p{method} eq 'GET') {
        return {
            action => 'display',
            content => kg::Elections::View->create_election(
                request      => $p{request},
            ),
        }

    } elsif ($p{method} eq 'POST') {

        my @errors;

       foreach my $f (qw/name election-date num-allowed/) {
            if (! scalar($p{request}->param($f))) {
                push @errors, "missing data for $f";
            }
        }

        if (my $election_date = scalar($p{request}->param('election-date'))) {
            if ($election_date !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
                push @errors, "date should be formatted YYYY-MM-DD, not '$election_date'";
            }
        }
        if (my $num_allowed = scalar($p{request}->param('num_allowed'))) {
            if ($num_allowed =~ /[^0-9]/) {
                push @errors, "num_allowed should be a number, not '$num_allowed'";
            }
        }

        if (@errors) {
            return {
                action => 'display',
                content => kg::Elections::View->create_election(
                    errors       => \@errors,
                    request      => $p{request},
                ),
            }
        }

        my $election = kg::Elections::Model::Election->new(
            name          => scalar($p{request}->param('name')),
            election_date => scalar($p{request}->param('election-date')),
            num_allowed   => scalar($p{request}->param('num-allowed')),
        );
        $election->save;

        my $xid= $election->xid;

        return {
            action => 'redirect',
            headers => {
                Location  => uri_for(
                    path => "/election-created",
                    xid => $xid,
                ),
            },
            debug => {
                election => $election,
            },
        };
    } else {
        die "unrecognized method $p{method} in call to create_election";
    }
}

sub election_created {
    my ($class, %p) = @_;

    if ($p{method} eq 'GET') {
        my @errors;
        my $xid = scalar($p{request}->param('xid')) or die "missing xid parameter";
        my $election = kg::Elections::Model::Election->load_by_xid($xid)
            or do { push @errors, "no election found for xid $xid" };

        return {
            action => 'display',
            content => kg::Elections::View->election_created(
                request => $p{request},
                election => $election,
                (@errors ? (errors => \@errors) : ()),
            ),
        }
    } elsif ($p{method} eq 'POST') {

        my @errors;

        foreach my $f (qw/voter-name election-xid/) {
            if (! scalar($p{request}->param($f))) {
                push @errors, "missing data for $f";
            }
        }

        my $xid = scalar($p{request}->param('election-xid'));

        my $election = kg::Elections::Model::Election->load_by_xid($xid)
            or do { push @errors, "no election found for xid $xid" };

        if (@errors) {
            return {
                action => 'display',
                content => kg::Elections::View->election_created(
                    errors       => \@errors,
                    request      => $p{request},
                ),
            }
        }

        my $voter_name = scalar($p{request}->param('voter-name'));
        my $user_sha1 = sha1_base64($voter_name);


    } else {
        die "unrecognized method $p{method} in call to election_created";
    }
}


sub vote_start {
    my ($class, %p) = @_;

    if ($p{method} eq 'GET') {
        my @errors;
        my $xid = scalar($p{request}->param('xid')) or die "missing xid parameter";
        my $election = kg::Elections::Model::Election->load_by_xid($xid)
            or do { push @errors, "no election found for xid $xid" };

        return {
            action => 'display',
            content => kg::Elections::View->vote_start(
                request => $p{request},
                election => $election,
                (@errors ? (errors => \@errors) : ()),
            ),
        }
    } else {
        die "unrecognized method $p{method} in call to vote_start";
    }
}

1;
