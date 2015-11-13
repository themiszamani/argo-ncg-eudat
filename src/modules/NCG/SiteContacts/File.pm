#!/usr/bin/perl -w
#
# Nagios configuration generator (WLCG probe based)
# Copyright (c) 2007 Emir Imamagic
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package NCG::SiteContacts::File;

use NCG::SiteContacts;
use strict;
use vars qw(@ISA);

@ISA=("NCG::SiteContacts");

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);

    if ( defined $self->{DB_FILE} ) {
        if (! -f $self->{DB_FILE})
        {
            $self->error("Can't find static file!");
            undef $self;
            return 0;
        }
        $self->{DB_FILES}->{$self->{DB_FILE}} = 1;
    }

    if ( defined $self->{DB_DIRECTORY} ) {
        if (! -d $self->{DB_DIRECTORY})
        {
            $self->error("Can't find static directory!");
            undef $self;
            return 0;
        }
        my $filelist = [];
        $self->_addRecurseDirs($filelist, $self->{DB_DIRECTORY});
        foreach my $file (@$filelist) {
            $self->{DB_FILES}->{$file} = 1;
        }
    }

    if ( !defined $self->{DB_DIRECTORY} && ! defined $self->{DB_FILE} ) {
        $self->error("File of directory name must be defined!");
        undef $self;
        return 0;
    }

    $self;
}

sub getData
{
    my $self = shift;
    my $line;
    my $fileHndl;
    
    foreach my $file (keys %{$self->{DB_FILES}}) {
        if (!open ($fileHndl, $file)) {
            $self->error("Cannot open static file!");
            return 0;
        }
        while ($line = <$fileHndl>) {
            next if ($line =~ /^#.*$/);
            if ($line =~ /^\s*(\S+?)!(\S+?)(!(\S+?))?(!(\S+?))?\s*$/) {
                my $action = $1;
                if ($action eq "ADD_CONTACT") {
                    $self->{SITEDB}->addContact($2);
                } elsif ($action eq "ADD_HOSTCONTACT") {
                    $self->{SITEDB}->addHostContact($2,$4);
                } elsif ($action eq "ADD_SERVICECONTACT") {
                    $self->{SITEDB}->addServiceContact($2,$4,$6);
                } elsif ($action eq "ADD_SERVICEFLAVOURCONTACT") {
                    $self->{SITEDB}->addServiceFlavourContact($2,$4,$6);
                } elsif ($action eq "REMOVE_CONTACT") {
                    $self->{SITEDB}->removeContact($2);
                } if ($action eq "ADD_SITE_CONTACT") {
                    $self->{SITEDB}->addContact($4) if ($2 eq $self->{SITEDB}->siteName);
                } if ($action eq "ENABLE_SITE_CONTACT") {
                    $self->{SITEDB}->addContact($4, 1) if ($2 eq $self->{SITEDB}->siteName);
                } if ($action eq "ENABLE_HOSTCONTACT") {
                    $self->{SITEDB}->addHostContact($2, $4, 1);
                } if ($action eq "ENABLE_SERVICEFLAVOURCONTACT") {
                    $self->{SITEDB}->addServiceFlavourContact($2, $4, $6, 1);
                } else {
                    $self->debug("Unknown command found: $1");
                }
            }
        }
        close ($fileHndl);
    }
    
    1;
}

=head1 NAME

NCG::SiteContacts::File

=head1 DESCRIPTION

Module NCG::SiteContacts::File enables adding and removing 
contacts.

Format:
  # add contact to all hosts
  ADD_CONTACT!email@email.com
  # add contact to all hosts of a given site
  ADD_SITE_CONTACT!sitename!email@email.com
  # add contact for defined hosts
  ADD_HOSTCONTACT!host!email@email.com
  # add contact for defined metric
  ADD_SERVICECONTACT!host!metricName!email@email.com
  # or you can use full Nagios name
  ADD_SERVICECONTACT!host!metricName-voName!email@email.com
  # or service flavour
  ADD_SERVICEFLAVOURCONTACT!host!ServiceFlavour!email@email.com
  # enables notifications for a site contact (see SAM-1424)
  # contact is added to site if it doesn't exist
  ENABLE_SITE_CONTACT!sitename!email@email.com
  # enables notifications for a host contact (see SAM-1424)
  # contact is added to host if it doesn't exist
  ENABLE_HOSTCONTACT!host!email@email.com
  # enables notifications for a service flavour (see SAM-2065)
  ENABLE_SERVICEFLAVOURCONTACT!host!ServiceFlavour!email@email.com
  # remove contact
  REMOVE_CONTACT!email@email.com

=head1 SYNOPSIS

  use NCG::SiteContacts::File;

  my $siteInfo = NCG::SiteContacts::File->new( { DB_FILE => '/path/to/rules' } );
  
  $siteInfo->getData();

=cut

1;
