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

package NCG::ConfigConverter;

use strict;
use NCG;
use XML::Simple;
use JSON;
use Sys::Hostname;
use POSIX qw(strftime);

use vars qw(@ISA);

@ISA=("NCG::ConfigPublish");

my $DEFAULT_VO='dteam';
my $DEFAULT_VO_HOST_FILTER = 1;

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);
    
    # set default values
    $self->{NAGIOS_ROLE} = 'site'
        unless (defined $self->{NAGIOS_ROLE});
    $self->{NAGIOS_SERVER} = hostname()
        unless (defined $self->{NAGIOS_SERVER});
    $self->{VO_HOST_FILTER} = $DEFAULT_VO_HOST_FILTER
        unless (defined $self->{VO_HOST_FILTER});
    
    if (! defined $self->{VO}) {
        $self->{VO} = $DEFAULT_VO;
    }
    $self->{VO} =~ s/^\s+//;
	$self->{VO} =~ s/\s+$//;
    foreach my $vo ( split (/\s*,\s*/, $self->{VO}) ) {
        $self->{VOS}->{$vo} = {};
    }
    
    foreach my $vo (keys %{$self->{VOS}}) {
        my $attrName = "VO_".uc($vo)."_DEFAULT_VO_FQAN";
        if (defined $self->{$attrName}) {
            foreach my $voFqan ( split (/\s*,\s*/, $self->{$attrName}) ) {
                $self->{VOS}->{$vo}->{FQAN}->{$voFqan}->{DEFAULT_FQAN} = 1;
            }
        }
        else {
            $self->{VOS}->{$vo}->{FQAN}->{$vo} = { DEFAULT_FQAN => 1 };
        }

        if ($self->{SITEDB}) {
            foreach my $voFqan ($self->{SITEDB}->getVoFqans($vo)) {
                if (!exists $self->{VOS}->{$vo}->{FQAN}->{$voFqan}) {
                    $self->{VOS}->{$vo}->{FQAN}->{$voFqan}->{DEFAULT_FQAN} = 0;
                }
            }
        }
    }
    
    $self->{SITE_NAME} = $self->{SITEDB}->siteName() if ($self->{SITEDB});

    # Check if SiteDB has ROC set
    my $roc;
    $roc = $self->{SITEDB}->siteROC if ($self->{SITEDB});
    # Otherwise hope that it is set in config
    $self->{ROC} = $roc if ($roc);

    $self;
}

sub _getMetricDepsArr {
    my $self = shift;
    my $host = shift;
    my $metric = shift;
    my $vo = shift;
    my $voFqan = shift;
    my $depArr = shift;
    my $voRemovedMetrics = shift;
    my $deps = $self->{SITEDB}->metricDependencies($host, $metric);

    foreach my $dep (keys %$deps) {
        if ($dep ne "hr.srce.GridProxy-Valid") {
            my $nagiosDep = $dep;

            next unless($self->{SITEDB}->hasMetric($host, $dep));

            next if (exists $voRemovedMetrics->{VO}->{$vo}->{$dep} ||
                     exists $voRemovedMetrics->{VO_FQAN}->{$voFqan}->{$dep});

            if ($self->{SITEDB}->metricFlag($host, $dep, "VO")) {
                $nagiosDep .= "-$voFqan";
            }
            my $depRef = {  hostName => $host,
                            nagiosName => $nagiosDep,
                            metricName => $dep };
            push @$depArr, {%{$depRef}};
        }
    }
}

sub _getMetricArr {
    my $self = shift;
    my $host = shift;
    my $metric = shift;
    my $voRemovedMetrics = shift;
    my $metricArr = shift;
    my $metricDocUrl = $self->{SITEDB}->metricDocUrl($host, $metric);
    my $parent = $self->{SITEDB}->metricParent($host, $metric);
    my $metricVo = $self->{SITEDB}->metricFlag($host, $metric, "VO");
    my $url = "https://$self->{NAGIOS_SERVER}/nagios/cgi-bin/extinfo.cgi?type=2&host=$host&service=";
    my @metricServices = $self->{SITEDB}->metricServices($host, $metric);
    my $config;

    if ($self->{SITEDB}->metricFlag($host, $metric, "PASSIVE")) {
        if ($parent) {
            return unless($self->{SITEDB}->hasMetric($host, $parent));
            $config = $self->{SITEDB}->metricConfig($host, $parent);
        } else {
            $config = $self->{SITEDB}->defaultConfig();
            $parent = 'no';
        } 
    } else {
        $config = $self->{SITEDB}->metricConfig($host, $metric);
    }

    my $metricRef = {
                    metricName => $metric,
                    config => {%{$config}}};
    $metricRef->{docUrl} = $metricDocUrl if ($metricDocUrl);
    $metricRef->{parent} = $parent if ($parent && $parent ne 'no');
    $metricRef->{services} = \@metricServices;

    foreach my $vo (keys %{$self->{VOS}}) {
        foreach my $voFqan (keys %{$self->{VOS}->{$vo}->{FQAN}}) {
            next if (exists $voRemovedMetrics->{VO}->{$vo}->{$metric} ||
                     exists $voRemovedMetrics->{VO_FQAN}->{$voFqan}->{$metric});
            my $nagiosName =  $metric;
            my $voName;
            my $lastPass = 0;
            if ($metricVo) {
                $nagiosName .= "-$voFqan";
                $metricRef->{vo} = $vo;
                $metricRef->{voFqan} = $voFqan;
            } else {
                $lastPass = 1;
            }
            $metricRef->{nagiosName} = $nagiosName;
            $metricRef->{url} = $url . $nagiosName;
            $metricRef->{dependency} = [];
            $self->_getMetricDepsArr($host, $metric, $vo, $voFqan, $metricRef->{dependency}, $voRemovedMetrics);
            push @$metricArr, {%{$metricRef}};
            last if ($lastPass);
        }
    }
}

sub _hostHasAnyVO {
	my $self = shift;
    my $host = shift;
    
    foreach my $vo (keys %{$self->{VOS}}) {
        return 1 if ($self->{SITEDB}->hasVO($host, $vo));
    }
    
    return 0;
}

sub getJSONConfig {
    my $self = shift;
    my $xmlOutRef = {};
    
    $self->{TIMESTAMP} = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time()));

    $xmlOutRef = {gatheredAt    => $self->{NAGIOS_SERVER},
                  timestamp     => $self->{TIMESTAMP},
                  role          => $self->{NAGIOS_ROLE},
                  ROC           => $self->{ROC},
                  sitename      => $self->{SITE_NAME},
                  host          => [] };

    # Iterate through hosts
    foreach my $host ($self->{SITEDB}->getHosts) {
        next if ($self->{VO_HOST_FILTER} && !$self->_hostHasAnyVO($host));
    
        my $supportsVo;
        my $hostRef = { hostName => $host,
                        metric   => [],
                        services => [] };

        foreach my $vo (keys %{$self->{VOS}}) {
            $supportsVo->{$vo} = $self->{SITEDB}->hasVO($host, $vo);
        }

        # fill profiles, vofqans
        my $profiles = $self->{SITEDB}->getHostProfiles($host);
        if ($profiles && ref $profiles eq 'HASH') {
            foreach my $profile (keys %$profiles) {
                $hostRef->{profiles}->{$profile} = [];
                foreach my $voFqan (keys %{$profiles->{$profile}}) {
                    if ($voFqan eq '*') {
                        foreach my $vo (keys %$supportsVo) {
                            foreach my $voFqanDefault (keys %{$self->{VOS}->{$vo}->{FQAN}}) {
                                if ($self->{VOS}->{$vo}->{FQAN}->{$voFqanDefault}->{DEFAULT_FQAN}) {
                                    push @{$hostRef->{profiles}->{$profile}}, $voFqanDefault;
                                }
                            }
                        }
                    } else {
                        push @{$hostRef->{profiles}->{$profile}}, $voFqan;
                    }
                }
            }
        }
        
        # fill services
        foreach my $service ($self->{SITEDB}->getServices($host)) {
            push @{$hostRef->{services}}, $service;
        }
        
        # first run, let's throw out metrics which don't support VO
        my $voRemovedMetrics = {};
        foreach my $metric ($self->{SITEDB}->getLocalMetrics($host)) {
            # ignore non published and non-vo-dependent metrics
            next if(!$self->{SITEDB}->metricFlag($host, $metric, "OBSESS") || !$self->{SITEDB}->metricFlag($host, $metric, "VO"));

            foreach my $vo (keys %{$self->{VOS}}) {
                if (!$self->{SITEDB}->hasVO($host, $vo, $metric)) {
                    $voRemovedMetrics->{VO}->{$vo}->{$metric} = 1;
                    next;
                }
                foreach my $voFqan (keys %{$self->{VOS}->{$vo}->{FQAN}}) {
                    if (!$self->{SITEDB}->hasMetricVoFqan($host, $metric, $vo, $voFqan, $self->{VOS}->{$vo}->{FQAN}->{$voFqan}->{DEFAULT_FQAN})) {
                        $voRemovedMetrics->{VO_FQAN}->{$voFqan}->{$metric} = 1;
                    }
                }
            }
        }

        foreach my $metric ($self->{SITEDB}->getLocalMetrics($host)) {
            next if (!$self->{SITEDB}->metricFlag($host, $metric, "OBSESS"));

            $self->_getMetricArr ($host, $metric, $voRemovedMetrics, $hostRef->{metric});
        }
        push @{$xmlOutRef->{host}}, {%{$hostRef}};
    }
    
    my $xmlOutStr = to_json($xmlOutRef);;

    return $xmlOutStr;
}

=head1 NAME

NCG::ConfigConverter

=head1 DESCRIPTION

The NCG::ConfigConverter module:
- generates JSON config from SiteDB module and JSON config 
contains list of checks which are publishedf from Nagios 
via obsessive handler.

This module is used by NCG::ConfigPublish::* .
=head1 SYNOPSIS

  use NCG::ConfigConverter;

  my $ncg = NCG::ConfigConverter->new( { SITEDB=> $sitedb } );

  my $jsonString = $ncg->getJSONConfig();

=cut

=head1 METHODS

=over

=item C<new>

  $ncg = NCG::ConfigConverter->new( $options );

Creates new NCG::ConfigConverter instance. Argument $options is hash
reference that can contain following elements:
  NAGIOS_ROLE - defines if this is site-level or multisite-level instance.
              - valid values: site, ROC
  (default: site)
  
  NAGIOS_SERVER - name of the Nagios server, set this variable if server
  is using name different from hostname()
  (default: hostname()

  ROC - name of ROC to which this site belongs.
  (default: none)

  VO - which VO credentials should be used for local probes. It is possible
  to define multiple VOs with comma separated list:
    VO = vo1,vo2,vo3,...
  (default: dteam)
  
  VO_<VO>_DEFAULT_VO_FQAN - if defined NCG will generate all checks for
  listed FQANs on profiles which are not tied to FQANs. In case of 
  profiles tied to FQAN NCG will generate checks only for the defined
  FQAN. 
  In case when <VO> is not listed in VO parameter it will be ignored.
  (default: none)
  
=item C<getJSONConfig>

  my $string = $ncg->getJSONConfig();

Method generates JSON configuration based on the data in NCG::SiteDB object
passed in NCG::ConfigConverter constructor. In NCG this method has to
be called after the NCG::LocalMetrics:*.

=back

=head1 SEE ALSO

=cut

1;
