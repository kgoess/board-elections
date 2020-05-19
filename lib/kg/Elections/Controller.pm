package kg::Elections::Controller;

use strict;
use warnings;

use Carp qw/croak/;
use CGI::Cookie;
use Data::Dump qw/dump/;

#use kg::Elections::Logger;
#use kg::Elections::Model::Event;
#use kg::Elections::Model::Person;
#use kg::Elections::Model::PersonEventMap;
#use kg::Elections::Utils qw/uri_escape/;

my %handler_for_path = (
    ''               => sub { shift->main_page(@_) },
    '/'              => sub { shift->main_page(@_) },
#    '/admin/logs'    => sub { shift->activity_logs(@_) },
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

#sub login_page {
#    my ($class, %p) = @_;
#
#    if ($p{method} eq 'GET') {
#        return {
#            action => 'display',
#            content => kg::Elections::View->login_page(
#                request      => $p{request},
#            ),
#        }
#
#    } elsif ($p{method} eq 'POST') {
#        my $id = scalar($p{request}->param('login_id'))
#            or die "missing login_id";
#
#        my $person = kg::Elections::Model::Person->load($id)
#            or die "no user found for id $id";;
#
#         my $cookie = CGI::Cookie->new(
#            -name  => 'Berkmo-GoC',
#            -value => "user_id:$id",
#            -expires => '+3M',
#         );
#
#        kg::Elections::Logger->new(current_user => $person)->debug("logged in");
#        return {
#            action => 'redirect',
#            headers => {
#                Location  => uri_for(path => "/"),
#            },
#            cookie => $cookie,
#        };
#    } else {
#        die "unrecognized method $p{method} in call to login_page";
#    }
#
#}


1;
