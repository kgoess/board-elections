#!/usr/bin/perl

use strict;
use warnings;

use local::lib '~apache/perl5', '--no-create';
#use lib '/home/kevin/git/elections/lib';

$ENV{SQLITE_FILE} = '/var/lib/elections/db/elections.sqlite';
$ENV{TT_INCLUDE_PATH} = '/var/lib/elections/templates';
$ENV{ELECTIONS_URI_BASE} = '/cgi-bin/elections.cgi';
$ENV{ELECTIONS_STATIC_URI_BASE} = '/elections-static/';


use kg::Elections::Controller::CGI;

kg::Elections::Controller::CGI->handler;
