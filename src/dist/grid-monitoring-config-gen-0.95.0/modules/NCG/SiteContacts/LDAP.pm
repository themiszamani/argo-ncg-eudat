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

package NCG::SiteContacts::LDAP;

use NCG::SiteContacts;
use strict;
use Net::LDAP;
use vars qw(@ISA);

@ISA=("NCG::SiteContacts");

my $DEFAULT_LDAP_CONNECT_TIMEOUT = 10;

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);
    
    # set default values
    if (! $self->{LDAP_ADDRESS}) {
        if ( ! ($self->{LDAP_ADDRESS} = $self->{SITEDB}->siteLDAP)) {
            $self->error("LDAP_ADDRESS must be defined!");
            undef $self;
            return;
        }
    }
    # default LDAP port is BDII
    if (! defined $self->{LDAP_PORT} ) {
        $self->{LDAP_PORT} = 2170;
    }

    # default BDII level is site
    if (! $self->{BDII_LEVEL} ) {
        $self->{BDII_LEVEL} = "site";
    } else {
        if ($self->{BDII_LEVEL} ne "site" && $self->{BDII_LEVEL} ne "top") {
            $self->error("BDII_LEVEL value unknown: $self->{BDII_LEVEL}. BDII_LEVEL can be: site, top.!");
            undef $self;
            return;
        }
    }
    
    if (! defined $self->{LDAP_CONNECT_TIMEOUT}) {
        $self->{LDAP_CONNECT_TIMEOUT} = $DEFAULT_LDAP_CONNECT_TIMEOUT;
    }

    $self;
}

sub getData {
    my $self = shift;
    my $sitename = shift || $self->{SITENAME} || "";

    if (! $self->{LDAP_BASEDN} ) {
        if ($self->{LDAP_PORT} == 2135) {
            $self->{LDAP_BASEDN} = "Mds-Vo-Name=local, O=Grid";
        } elsif ($self->{LDAP_PORT} == 2170) {
            if ($self->{BDII_LEVEL} eq "site") {
                $self->{LDAP_BASEDN} = "Mds-Vo-Name=$sitename, O=Grid";
            } elsif ($self->{BDII_LEVEL} eq "top") {
                $self->{LDAP_BASEDN} = "Mds-Vo-Name=$sitename, Mds-Vo-Name=local, O=Grid";
            }
        } else {
            $self->warning("Base DN not defined, port ". $self->{LDAP_PORT} ." is not BDII or MDS. Assuming 'O=Grid'");
            $self->{LDAP_BASEDN} = "O=Grid";
        }
    }

    $self->verbose("Getting info from LDAP: " . $self->{LDAP_ADDRESS} . ":" . $self->{LDAP_PORT} . "/" . $self->{LDAP_BASEDN});

    my $ldap = Net::LDAP->new( $self->{LDAP_ADDRESS}, port => $self->{LDAP_PORT}, timeout => $self->{LDAP_CONNECT_TIMEOUT}, async => 1 );
    if (! defined $ldap ) {
        $self->error("Cannot connect to $self->{LDAP_ADDRESS}:$self->{LDAP_PORT}");
        return 0;
    }
    my $mesg = $ldap->bind( anonymous => 1 );
    if ($mesg->code) {
        $self->error("Could not bind to LDAP: ".$mesg->error);
        return 0;
    }

    # Get site contact address
    $mesg = $ldap->search ( base => $self->{LDAP_BASEDN},
                           filter => "(objectClass=GlueSite)",
                           attrs=> ['GlueSiteSysAdminContact'],
                           timelimit => 60 );
    if (!$mesg->code && $mesg->count != 0 && $mesg->entry(0)->get_value('GlueSiteSysAdminContact') =~ /^mailto:\s*(\S+)/) {
        my $foundContact = $1;
        foreach my $contact (split(/\,/, $foundContact)) {
            $self->{SITEDB}->addContact($contact);
        }
    }
    
    1;
}

sub baseDN {
    my $self = shift;
    my $value = shift;
    $self->{LDAP_BASEDN} = $value if (defined $value);
    $self->{LDAP_BASEDN};
}

sub address {
    my $self = shift;
    my $value = shift;
    $self->{LDAP_ADDRESS} = $value if (defined $value);
    $self->{LDAP_ADDRESS};
}

sub port {
    my $self = shift;
    my $value = shift;
    $self->{LDAP_PORT} = $value if (defined $value);
    $self->{LDAP_PORT};
}

sub bdiiLevel {
    my $self = shift;
    my $value = shift;
    $self->{BDII_LEVEL} = $value if (defined $value);
    $self->{BDII_LEVEL};
}

=head1 NAME

NCG::SiteContacts::LDAP

=head1 DESCRIPTION

The NCG::SiteContacts::LDAP module extends NCG::SiteContacts module. Module
extracts site contact from LDAP-based information services (e.g.
BDII, Globus MDS).

=head1 SYNOPSIS

  use NCG::SiteContacts::LDAP;

  my $siteInfo = NCG::SiteContacts::LDAP->new({LDAP_ADDRESS=>'ldap.server.com', 
                                           LDAP_PORT=>2170, 
                                           LDAP_BASEDN=>'O=Grid'});

  $siteInfo->getData();

=cut

=head1 METHODS

=over

=item C<new>

  my $siteInfo = NCG::SiteContacts::LDAP->new($options);

Creates new NCG::SiteContacts::LDAP instance. Argument $options is hash reference that
can contains following elements:
  LDAP_ADDRESS - address of LDAP server (default: localhost)
  LDAP_PORT - port of LDAP server (default: 2170)
  LDAP_BASEDN - basedn used when querying LDAP server
  BDII_LEVEL - which BDII level is queried, this option will
               define default base DN value
               possible values: site, top
  (default: site)
  LDAP_CONNECT_TIMEOUT - timeout for binding to LDAP server
  (default: 10)  

=item C<getData>

  print $siteInfo->getData;

Method retrieves site contact information from BDII.
(GlueSiteSysAdminContact)

=back

=head1 SEE ALSO

NCG::SiteContacts

=cut

1;
