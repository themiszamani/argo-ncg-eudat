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

package NCG::SiteSet::ATP;

use strict;
use NCG::SiteSet;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

use vars qw(@ISA);

@ISA=("NCG::SiteSet");

my $DEFAULT_ATP_ROOT_URL = "https://grid-monitoring.cern.ch/atp";
my $DEFAULT_X509_CERT = '/etc/grid-security/hostcert.pem';
my $DEFAULT_X509_KEY = '/etc/grid-security/hostkey.pem';
my $DEFAULT_ATP_ROOT_URL_SUFFIX = "/api/search/siteregionvo/json";
my $DEFAULT_ATP_ROOT_URL_VO_SUFFIX = "/api/search/vofeeds/json";

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

    if (! exists $self->{CERT_STATUS}) {
        $self->{CERT_STATUS} = 'Y';
    }
    if (! exists $self->{PROD_STATUS}) {
        $self->{PROD_STATUS} = 'Production';
    }
    if (! exists $self->{SITE_MONITORED}) {
        $self->{SITE_MONITORED} = 'Y';
    }
    if (! exists $self->{FEED_TYPE}) {
        $self->{FEED_TYPE} = 'generic';
    } else {
        if ($self->{FEED_TYPE} =~ /vo/i) {
            unless ($self->{VO}) {
                $self->error("Parameter VO must be defined if FEED_TYPE is \"vo\".");
                return;
            }
        }
    }
    $self->{TIMEOUT} = $self->{DEFAULT_HTTP_TIMEOUT} unless ($self->{TIMEOUT});

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
    my $url = $self->{ATP_ROOT_URL} . $DEFAULT_ATP_ROOT_URL_SUFFIX;
    my @urlExt;
    local %ENV = %ENV;

    $ENV{HTTPS_KEY_FILE} = $self->{X509_KEY};
    $ENV{HTTPS_CERT_FILE} = $self->{X509_CERT};
    $ENV{HTTPS_CA_DIR} = '/etc/grid-security/certificates';

    my $ua = LWP::UserAgent->new(timeout=>$self->{TIMEOUT}, env_proxy=>1);
    $ua->agent("NCG::SiteSet::ATP");

    push @urlExt, 'ismonitored=on' if ($self->{SITE_MONITORED} ne 'N');
    if ($self->{FEED_TYPE} =~ /vo/i) {
        push @urlExt, 'vo=' . $self->{VO};        
        $url = $self->{ATP_ROOT_URL} . $DEFAULT_ATP_ROOT_URL_VO_SUFFIX;
    } else {
        if ($self->{ROC}) {
            push @urlExt, 'region=' . $self->{ROC};
        }
        if ($self->{CERT_STATUS}) {
            push @urlExt, 'certifstatus=' . $self->{CERT_STATUS};
        }
        $url = $self->{ATP_ROOT_URL} . $DEFAULT_ATP_ROOT_URL_SUFFIX;
    }

    if (@urlExt) {
        $url .= '?' . join ( '&', @urlExt);
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
        if ($self->{FEED_TYPE} =~ /vo/i) {
            foreach my $site (@{$jsonRef}) {
                if ($site->{atp_site} && !exists $self->{SITES}->{$site->{atp_site}}) {
                    $self->verbose ("Found site: $site->{atp_site}.");
                    $self->{SITES}->{$site->{atp_site}} = NCG::SiteDB->new ({SITENAME=>$site->{atp_site}});
                }
            }
        } else {
            foreach my $site (@{$jsonRef}) {
                if ($site->{site}) {
                    $self->verbose ("Found site: $site->{site}.");
                    $self->{SITES}->{$site->{site}} = NCG::SiteDB->new ({SITENAME=>$site->{site}, ROC=>$site->{region}});
                }
            }
        }
    } else {
        $self->error("Invalid JSON format: ".Dumper($jsonRef));
        return;
    }

    1;
}

=head1 NAME

NCG::SiteSet::ATP

=head1 DESCRIPTION

The NCG::SiteSet::ATP module extends NCG::SiteSet module. Module
extracts site information from ATP (eng. Aggregated Topology Provider)
database.

=head1 SYNOPSIS

  use NCG::SiteInfo::ATP;

  my $siteInfo = NCG::SiteInfo::ATP->new({ { SITES=> $sitedb } );

  $siteInfo->getData();

=cut

=head1 METHODS

=over

=item C<new>

  $siteInfo = NCG::SiteInfo::ATP->new( $options );

Creates new NCG::SiteInfo::ATP instance. Argument $options is hash
reference that can contain following elements:
  ATP_ROOT_URL - root URL used for ATP DB query interface
  (default: http://grid-monitoring.cern.ch/atp/)
  
  FEED_TYPE - defines type of feed, currently only two are supported:
                vo - uses VO query /api/search/vofeeds
                generic - uses generic query /api/search/siteregionvo
            - default: generic

  ROC - name of the region which is being monitored
      - default:

  PROD_STATUS - production status of site
              - (for possible values see ATP documentation)
              - default: Production

  CERT_STATUS - certification status of site 
              - (for possible values see ATP documentation)
              - default: Y

  SITE_MONITORED - is the site monitored or not
                 - possible values: Y, N
                 - default: Y

  VO - VO used in case of FEED_TYPE vo 
     - parameter must be set if FEED_TYPE is vo
     - default:

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

NCG::Site

=cut

1;
