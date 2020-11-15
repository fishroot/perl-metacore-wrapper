#! /usr/bin/perl -w
#
# Perl Wrapper for MetaCore(tm) CGI RPC API
# Version 0.0.2
# Copyright (C) 2012, Patrick Michl <patrick.michl (at) gmail.com>

package metacore;

use warnings;
use strict;
use utf8;
use CGI;
use Term::ReadKey ();
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

#
# Constructor
#

sub new {
    my ($class) = @_;
    my $self = {
        _key => undef,
        _version => undef,
        _ua  => LWP::UserAgent->new(), # user agent for post requests
        _api => "https://portal.genego.com/api/rpc.cgi",
    };
    bless $self, $class;
    return $self;
}

#
# Accessors for api and auth_key
#

sub api {
    my ( $self, $api ) = @_;
    $self->{_api} = $api if defined($api);
    return $self->{_api};
}

sub key {
    my ( $self, $key ) = @_;
    $self->{_key} = $key if defined($key);
    return $self->{_key};
}

#
# MetaCore login
#

sub login {
    my ($self, $login, $passwd) = @_;
    
    # force login
    if (!defined($login)) {
        Term::ReadKey::ReadMode("noecho");
        print "login: ";
        chomp(my $login = <STDIN>);
        print "\n";
        Term::ReadKey::ReadMode(0);
    }

    # force passwd
    if (!defined($passwd)) {
        Term::ReadKey::ReadMode("noecho");
        print "passwd: ";
        chomp(my $passwd = <STDIN>);
        print "\n";
        Term::ReadKey::ReadMode(0);
    }

    # get response
    my $response = $self->{_ua}->post($self->{_api}, {
        proc => 'login',
        login => $login,
        passwd => $passwd,
    });

    # evaluate response
    my $return = undef;
    if ($response->is_success) {
        my $xs = XML::Simple->new();
        my $ref = $xs->XMLin($response->decoded_content);
      
        if ($ref->{Code} == 0) {
            # everything went well
            $self->{_key} = $ref->{Result}->{Row}->{Field}->{Value};
            $return = $self->{_key};
        } else {
            # error
            $return = "MetaCore: $ref->{Message}\n";
        }
    } else {
        $return = $response->status_line;
    }

    return $return;
}

#
# MetaCore logout
#

sub logout {
    my ($self) = @_;

    # get response
    my $response = $self->{_ua}->post($self->{_api}, {
        proc => 'logout',
        auth_key => $self->{_key},
    });

    # evaluate response
    my $return = undef;
    if ($response->is_success) {
        my $xs = XML::Simple->new();
        my $ref = $xs->XMLin($response->decoded_content);

        if ($ref->{Code} == 0) {
            # everything went well
            $return = 1;
        } else {
            # error
            $return = "MetaCore: $ref->{Message}\n";
        }
    } else {
        $return = $response->status_line;
    }

    return $return;
}

#
# MetaCore getVersion
#

sub getVersion {
    my ($self) = @_;

    # get response
    my $response = $self->{_ua}->post($self->{_api}, {
        proc => 'getVersion',
        auth_key => $self->{_key},
    });

    # evaluate response
    my $return = undef;
    if ($response->is_success) {
        my $xs = XML::Simple->new();
        my $ref = $xs->XMLin($response->decoded_content);
      
        if ($ref->{Code} == 0) {
            # everything went well
            $self->{_version} = $ref->{Result}->{Row}->{Field}->{Value};
            $return = $self->{_version};
        } else {
            # error
            $return = "MetaCore: $ref->{Message}\n";
        }
    } else {
        $return = $response->status_line;
    }

    return $return;
}

#
# MetaCore getGenePageURL
#

sub getGenePageURL {
    my ($self, $idtype, $id) = @_;

    # set EntrezGeneID as default
    if (!defined($idtype)) {
        $idtype = 'LOCUSLINK';
    }

    # get response
    my $response = $self->{_ua}->post($self->{_api}, {
        proc => 'getGenePageURL',
        auth_key => $self->{_key},
        idtype => $idtype,
        id => $id,
    });

    # evaluate response
    my $return = undef;
    if ($response->is_success) {
        my $xs = XML::Simple->new();
        my $ref = $xs->XMLin($response->decoded_content);
      
        if ($ref->{Code} == 0) {
            # everything went well
            $self->{_version} = $ref->{Result}->{Row}->{Field}->{Value};
            $return = $self->{_version};
        } else {
            # error
            $return = "MetaCore: $ref->{Message}\n";
        }
    } else {
        $return = $response->status_line;
    }

    return $return;
}

#
# MetaCore getMapsByObject
#

sub getMapsByObject {
    my ($self, $idtype, $id) = @_;

    # usage Error
    if (!defined($id) or !defined($idtype)) {
        print "usage: getMapsByObject(IDType, ID)\n";
        return 0;
    }

    # get response
    my $response = $self->{_ua}->post($self->{_api}, {
        proc => 'getMapsByObject',
        auth_key => $self->{_key},
        idtype => $idtype,
        id => $id,
    });

    # http request Errors
    if (!$response->is_success) {
        my $error = $response->status_line;
        print "HTTP request error: $error\n";
        return 0;
    }

    my $xs = XML::Simple->new();
    my $ref = $xs->XMLin($response->decoded_content);

    # metacore request error
    if ($ref->{Code} == 1) {
        my $error = $ref->{Message};
        print "MetaCore request error: $error\n";
        return 0;
    }

    # empty response
    if (!defined($ref->{Result}->{Row})) {
        return 0;
    }

    my $row = $ref->{Result}->{Row};

    # single value response
    # -> build array with single EntrezID
    #if (defined($ref->{Result}->{Row}->{Field})) {
    #    my $return = undef;
    #    push(@$return, $ref->{Result}->{Row}->{Field}->{MapID}->{Value});
    #    return $return;
    #}

    # multi value response
    # -> build array with EntrezIDs
    my $return = undef;
    foreach my $entry (@$row){
        my $MapID = $entry->{Field}->{MapID}->{Value};
        my $MapName = $entry->{Field}->{MapName}->{Value};
        my $URL = $entry->{Field}->{URL}->{Value};
        push(@$return, [$MapID, $MapName, $URL]);
    }
    return $return;
}

#
# MetaCore doRegulationSearch
#
# -> not jet implemented

sub doRegulationSearch {
    my ($self, $textToSearch) = @_;

    # usage Error
    if (!defined($textToSearch)) {
        print "usage: doRegulationSearch(textToSearch)\n";
        return 0;
    }

    # get response
    my $response = $self->{_ua}->post($self->{_api}, {
        proc => 'doRegulationSearch',
        auth_key => $self->{_key},
        texttosearch => $textToSearch,
    });

    # http request Errors
    if (!$response->is_success) {
        my $error = $response->status_line;
        print "HTTP request error: $error\n";
        return 0;
    }

    my $xs = XML::Simple->new();
    my $ref = $xs->XMLin($response->decoded_content);

    # metacore request error
    if ($ref->{Code} == 1) {
        my $error = $ref->{Message};
        print "MetaCore request error: $error\n";
        return 0;
    }

    # empty response
    if (!defined($ref->{Result}->{Row})) {
        return 0;
    }

    my $row = $ref->{Result}->{Row};

    return $row;
}

#
# MetaCore getJobs
#
# -> not jet implemented

sub getJobs {
    my ($self) = @_;

    # get response
    my $response = $self->{_ua}->post($self->{_api}, {
        proc => 'getJobs',
        auth_key => $self->{_key},
    });

    # evaluate response
    my $return = undef;
    if ($response->is_success) {
        my $xs = XML::Simple->new();
        my $ref = $xs->XMLin($response->decoded_content);
      
        if ($ref->{Code} == 0) {
            # everything went well

            # TODO: Convert XML Object "$ref" in usable format!!
            $return = $ref;
        } else {
            # error
            $return = "MetaCore: $ref->{Message}\n";
        }
    } else {
        $return = $response->status_line;
    }

    return $return;
}

1;
