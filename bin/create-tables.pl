#!/usr/bin/perl

use strict;
use warnings;


# usage:
#
# sudo sh -c "SQLITE_FILE=/var/lib/elections/db/elections.sqlite PERL5LIB=$PERL5LIB bin/create-tables.pl" && sudo chown apache.apache /var/lib/elections/db/elections.sqlite

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use kg::Elections::Model::Election;
use kg::Elections::Model::Vote;

kg::Elections::Model::Election->create_table;
kg::Elections::Model::Vote->create_table;
