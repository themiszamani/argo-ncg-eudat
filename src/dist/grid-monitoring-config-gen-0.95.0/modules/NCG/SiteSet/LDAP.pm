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

package NCG::SiteSet::LDAP;

use NCG::SiteSet;
use strict;
use Net::LDAP;
use vars qw(@ISA);

@ISA=("NCG::SiteSet");

my $DEFAULT_LDAP_CONNECT_TIMEOUT = 10;

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);
    
    # set default values
    if (! $self->{LDAP_ADDRESS}) {
        $self->error("LDAP_ADDRESS must be defined!");
        undef $self;
        return;
    }
    # default LDAP port is BDII
    if (! defined $self->{LDAP_PORT} ) {
        $self->{LDAP_PORT} = 2170;
    }
    
    if (! defined $self->{LDAP_CONNECT_TIMEOUT}) {
        $self->{LDAP_CONNECT_TIMEOUT} = $DEFAULT_LDAP_CONNECT_TIMEOUT;
    }

    $self;
}

sub getData {
    my $self = shift;

    my $mesg;
    my $sitename;
    my $port;
    my $entry;

    if (! $self->{LDAP_BASEDN} ) {
        $self->{LDAP_BASEDN} = "Mds-Vo-Name=local, O=Grid";
    }

    $self->verbose("Getting info from LDAP: " . $self->{LDAP_ADDRESS} . ":" . $self->{LDAP_PORT} . "/" . $self->{LDAP_BASEDN});

    my $ldap = Net::LDAP->new( $self->{LDAP_ADDRESS}, port => $self->{LDAP_PORT}, timeout => $self->{LDAP_CONNECT_TIMEOUT}, async => 1 );
    if (! defined $ldap ) {
        $self->error("Cannot connect to $self->{LDAP_ADDRESS}:$self->{LDAP_PORT}");
        return 0;
    }
    $mesg = $ldap->bind( anonymous => 1 );
    if ($mesg->code) {
        $self->error("Could not bind to LDAP: ".$mesg->error);
        return 0;
    }

    my $filter;
    if ($self->{LDAP_FILTER}) {
        $filter = "(&(objectClass=GlueSite)(".$self->{LDAP_FILTER}."))";
    } else {
        $filter = "(objectClass=GlueSite)";
    }

    # Set site contact address
    $mesg = $ldap->search ( base => $self->{LDAP_BASEDN},
                           filter => $filter,
                           attrs=> ['GlueSiteName', 'GlueSiteLocation', 'GlueSiteOtherInfo'],
                           timelimit => 60 );
    if ($mesg->code) {
        $self->error("Could not fetch site info from LDAP: ".$mesg->error);
    } else {
        foreach $entry ($mesg->entries()) {
            $sitename = $entry->get_value('GlueSiteName');
            $self->verbose("Found site: $sitename");
            if (!exists $self->{SITES}->{$sitename}) {
                $self->{SITES}->{$sitename} = NCG::SiteDB->new ({SITENAME=>$sitename});
            }  
           
            my $country = $entry->get_value('GlueSiteLocation');
            if ($country =~ /(\S.+?)\,\s*(\S.*\S)\s*/) {
                my $testString = $2;
                if ($testString =~ /(\`|\~|\!|\$|\%|\^|\*|\||\'|\"|\<|\>|\?|\,|\(|\))/) {
                    $self->error('Found country entry with illegal character (`~!$%^*|\'"<>?,()): '.$testString);
                } else {
                    $self->{SITES}->{$sitename}->siteCountry($testString);
                }
            }

            foreach my $attr ($entry->get_value('GlueSiteOtherInfo')) {
                if ($attr =~ /GRID=\s*(\S.*\S)\s*/) {
                    my $testString = $1;
                    if ($testString =~ /(\`|\~|\!|\$|\%|\^|\*|\||\'|\"|\<|\>|\?|\,|\(|\))/) {
                        $self->error('Found GlueSiteOtherInfo entry with illegal character (`~!$%^*|\'"<>?,()): '.$testString);
                    } else {
                        $self->{SITES}->{$sitename}->addSiteGrid($testString);
                    }
                }
                if ($attr =~ /(EGEE_ROC|EGI_NGI)=\s*(\S.*\S)\s*/) {
                    my $testString = $1;
                    if ($testString =~ /(\`|\~|\!|\$|\%|\^|\*|\||\'|\"|\<|\>|\?|\,|\(|\))/) {
                        $self->error('Found GlueSiteOtherInfo entry with illegal character (`~!$%^*|\'"<>?,()): '.$testString);
                    } else {
                        $self->{SITES}->{$sitename}->siteROC($testString);
                    }
                }
            }

            my $basedn = "Mds-Vo-Name=$sitename," . $self->{LDAP_BASEDN};
            # Get remote path that selected VO can use
            my $mesg1 = $ldap->search ( base => $basedn,
                                        filter => "(GlueServiceType=bdii_site)",
                                        attrs => ['GlueServiceEndpoint'],
                                        timelimit => 60 );
            if ($mesg1->code) {
                $self->error("Could not fetch Site BDII info for site $sitename from LDAP: ".$mesg->error);
            } else {
                foreach my $entry1 ($mesg1->entries()) {
                    my $bdii = $entry1->get_value('GlueServiceEndpoint');
                    if ($bdii && $bdii =~ /^ldap:\/\/([-_.A-Za-z0-9]+\$?):\d+/) {
                        $self->{SITES}->{$sitename}->siteLDAP($1);
                    }
                    last;
                }
            }
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

sub filter {
    my $self = shift;
    my $value = shift;
    $self->{LDAP_FILTER} = $value if (defined $value);
    $self->{LDAP_FILTER};
}

=head1 NAME

NCG::SiteSet::LDAP

=head1 DESCRIPTION

The NCG::SiteSet::LDAP module extends NCG::SiteSet module. Module
extracts list of sites from LDAP-based information service (e.g.
BDII, Globus MDS). 

Users can use parameter LDAP_FILTER to filter sites which should be 
included in multisite configuration. Keep in mind that module constructs 
final filter in following way:
 (&(objectClass=GlueSite)(${LDAP_FILTER}))

=head1 SYNOPSIS

  use NCG::SiteSet::LDAP;

  my $siteInfo = NCG::SiteSet::LDAP->new({LDAP_ADDRESS=>'ldap.server.com',
                                           LDAP_PORT=>2170,
                                           LDAP_FILTER=>'GlueSiteOtherInfo=EGEE_ROC=CE',});

  $siteInfo->getData();

=cut

=head1 METHODS

=over

=item C<new>

  my $siteInfo = NCG::SiteSet::LDAP->new($options); 

Creates new NCG::SiteSet::LDAP instance. Argument $options is hash reference that
can contains following elements:
  LDAP_ADDRESS - address of LDAP server (default: localhost)
  LDAP_PORT - port of LDAP server (default: 2170)
  LDAP_BASEDN - basedn used when querying LDAP server
  LDAP_FILTER - filter to be used for filtering sites
  LDAP_CONNECT_TIMEOUT - timeout for binding to LDAP server
  (default: 10)  

=item C<address>

  print $siteInfo->address;
  $siteInfo->address('ldap.server.com');

Accessor method for property address.

=item C<port>

  print $siteInfo->port;
  $siteInfo->port(2135);

Accessor method for property port.

=item C<baseDN>

  print $siteInfo->baseDN;
  $siteInfo->baseDN('Mds-Vo-Name=myegeesite,O=Grid');

Accessor method for property baseDN.

=item C<filter>

  print $siteInfo->filter;
  $siteInfo->filter('GlueSiteOtherInfo=EGEE_ROC=CE');

Accessor method for property baseDN.

=back

=head1 SEE ALSO

NCG::SiteInfo

=cut

1;
