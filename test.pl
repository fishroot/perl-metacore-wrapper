#! /usr/bin/perl -w
#
# Copyright (C) 2012, Patrick Michl <patrick.michl (at) gmail.com>

use strict;
use warnings;
use utf8;
use FindBin;                  # locate this script
use lib "$FindBin::Bin/lib";  # use the current lib directory
use metacore;                 # wrapper for MetaCore external API
use Data::Dumper;

# create MetaCore wrapper instance
my $mc = new metacore();

# login using some user and password and get session key
my $mcKey = $mc->login('YOUR_USER', 'YOUR_PASSWORD');
print "MetaCore Session Key: $mcKey\n";

# try metacore function 'getVersion'
my $mcVersion = $mc->getVersion();
print "MetaCore Version: $mcVersion\n";

# try metacore function 'doRegulationSearch'
print Dumper($mc->doRegulationSearch('a'));

# logout
$mc->logout();
