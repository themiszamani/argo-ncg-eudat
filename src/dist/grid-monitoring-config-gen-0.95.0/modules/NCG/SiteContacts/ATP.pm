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

package NCG::SiteContacts::ATP;

use strict;
use NCG::SiteContacts;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

use vars qw(@ISA);

@ISA=("NCG::SiteInfo");

my $DEFAULT_ATP_ROOT_URL = "https://grid-monitoring.cern.ch/atp";
my $DEFAULT_X509_CERT = "/etc/grid-security/hostcert.pem";
my $DEFAULT_X509_KEY = "/etc/grid-security/hostkey.pem";
my $SITE_GET_METHOD = "/api/search/contactsite/json";
my $ROC_GET_METHOD = "/api/search/contactgroup/json";
my $ALARM_GET_METHOD = "/api/search/site/json";

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);

    # set default values
    if (! $self->{ATP_ROOT_URL}) {
        $self->{ATP_ROOT_URL} = $DEFAULT_ATP_ROOT_URL;
    }
    
    if (! $self->{X509_CERT}) {
        $self->{X509_CERT} = $DEFAULT_X509_CERT;
    }

    if (! $self->{X509_KEY}) {
        $self->{X509_KEY} = $DEFAULT_X509_KEY;
    }

    if (! -f $self->{X509_KEY} || ! -r $self->{X509_KEY} ) {
        $self->error("X509 key ($self->{X509_KEY}) does not exist or it is not readable!");
        undef $self;
        return;
    }

    if (! -f $self->{X509_CERT} || ! -r $self->{X509_CERT} ) {
        $self->error("X509 certificate ($self->{X509_CERT}) does not exist or it is not readable!");
        undef $self;
        return;
    }
    $self->{TIMEOUT} = $self->{DEFAULT_HTTP_TIMEOUT} unless ($self->{TIMEOUT});

    $self->{CONTACT_TYPE} = 'site' unless ($self->{CONTACT_TYPE});
    if ($self->{CONTACT_TYPE} =~ /roc/) {
        $self->{CONTACT_TYPE} = 'roc';
        $self->{GET_METHOD} = $ROC_GET_METHOD;
    } elsif ($self->{CONTACT_TYPE} =~ /site/) {
        $self->{CONTACT_TYPE} = 'site';
        $self->{GET_METHOD} = $SITE_GET_METHOD;
    } elsif ($self->{CONTACT_TYPE} =~ /alarm/) {
        $self->{CONTACT_TYPE} = 'alarm';
        $self->{GET_METHOD} = $ALARM_GET_METHOD;
    } else {
        $self->error("Unsupported CONTACT_TYPE defined: ".$self->{CONTACT_TYPE});
        undef $self;
        return;
    }

    $self;
}

sub ATPRootUrl {
    my $self = shift;
    my $value = shift;
    $self->{ATP_ROOT_URL} = $value if (defined $value);
    $self->{ATP_ROOT_URL};
}

sub defaultATPRootUrl {
    my $self = shift;
    return $DEFAULT_ATP_ROOT_URL;
}

sub getData
{
    my $self = shift;
    my $sitename = shift || $self->{SITENAME};
    my $roc = $self->{SITEDB}->siteROC || $self->{ROC};
    my $url;
    local %ENV = %ENV;

    $ENV{HTTPS_KEY_FILE} = $self->{X509_KEY};
    $ENV{HTTPS_CERT_FILE} = $self->{X509_CERT};
    $ENV{HTTPS_CA_DIR} = '/etc/grid-security/certificates';

    my $ua = LWP::UserAgent->new(timeout=>$self->{TIMEOUT}, env_proxy=>1);
    $ua->agent("NCG::SiteInfo::ATP");

    $url = $self->{ATP_ROOT_URL} . $self->{GET_METHOD};

    if ($self->{CONTACT_TYPE} eq 'site') {
        $url .= '?sitename=' . $sitename;
    } elsif ($self->{CONTACT_TYPE} eq 'roc') {
        $url .= '?groupname=' . $roc if ($roc);
    } elsif ($self->{CONTACT_TYPE} eq 'alarm') {
        $url .= '?ismonitored=on&sitename=' . $sitename;
    }

    my $req = HTTP::Request->new(GET => $url);
    my $res = $self->safeHTTPSCall($ua,$req);

    if (!$res->is_success) {
        $self->error("Could not get results from ATP: ".$res->status_line);
        return;
    }

    my $jsonRef;
    eval {
        $jsonRef = from_json($res->content);
    };
    if ($@) {
        $self->error("Error parsing JSON response: ".$@);
        $self->error("Original ATP response: ".$res->content);
        return;
    }

    if ($jsonRef && ref $jsonRef eq "ARRAY") {
        if ($self->{CONTACT_TYPE} eq 'alarm') {
            my $email;
            foreach my $site (@{$jsonRef}) {
                next if ( ref $site ne "HASH" );
                $email = $site->{contactemail};
                last;
            }
            if ($email) {
                foreach my $emailAddr (split(/(;|,)/,$email)) {
                    $self->{SITEDB}->addContact($emailAddr) if ($emailAddr=~ /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i);
                }
            }
        } else {
            foreach my $contactATP (@{$jsonRef}) {
                next if ( ref $contactATP->{contact} ne "HASH" );
                next if ($contactATP->{contact}->{dn} =~ /,/);
                $self->{SITEDB}->addUser($contactATP->{contact}->{dn},
                                         $contactATP->{contact}->{name},
                                         $contactATP->{contact}->{email});

            }
        }
    } else {
        $self->error("Invalid JSON format: ".Dumper($jsonRef));
        return;
    }

    1;
}

=head1 NAME

NCG::SiteContacts::ATP

=head1 DESCRIPTION

The NCG::SiteContacts::ATP module extends NCG::SiteContacts module. Module
extracts site information from ATP (eng. Aggregated Topology Provider)
database.

=head1 SYNOPSIS

  use NCG::SiteContacts::ATP;

  my $siteInfo = NCG::SiteContacts::ATP->new({ { SITEDB=> $sitedb } );

  $siteInfo->getData();

=cut

=head1 METHODS

=over

=item C<new>

  $siteInfo = NCG::SiteContacts::ATP->new( $options );

Creates new NCG::SiteContacts::ATP instance. Argument $options is hash
reference that can contain following elements:
  ATP_ROOT_URL - root URL used for ATP DB query interface
  (default: http://grid-monitoring.cern.ch/atp)

  CONTACT_TYPE - which type of contacts to retrieve. Currently supported
                 options are:
                    - site (default): get site contacts
                    - roc: get roc contacts
                    - alarm: get contacts which should receive emails

  ROC - roc name must be set in case when CONTACT_TYPE is set to 'roc'.

  TIMEOUT - HTTP timeout,
  (default: DEFAULT_HTTP_TIMEOUT inherited from NCG)

=item C<ATPRootUrl>

  print $ncg->ATPRootUrl;
  $ncg->ATPRootUrl('http://sam.server.com/new-api/');
  
Accessor method for property ATP_ROOT_URL.

=item C<defaultATPRootUrl>

  print $ncg->ATPRootUrl;

Read only accessor method for default value of property
ATP_ROOT_URL.

=back

=head1 SEE ALSO

NCG::SiteContacts

=cut

1;
