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

package NCG::SiteDB;
use strict;
use Socket;
use NCG;
use vars qw(@ISA);

@ISA=("NCG");

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);
    $self->{METRIC_COUNT} = 0;
    $self;
}

# Add methods

sub addParent {
    my $self = shift;
    my $host = shift or return;
    my $ip = shift;
    
    if (!$ip) {
        my ($hostReal, $aliases, $addrtype, $length, @addrs);

        unless ( ($hostReal, $aliases, $addrtype, $length, @addrs) = gethostbyname($host)) {
            return;
        }

        $ip = join ('.', unpack('C4', $addrs[0]));
    }

    $self->verbose ("Found site parent: $host, $ip.");
    $self->{PARENT} = {HOSTNAME=>$host, ADDRESS=>$ip};
    1;
}

sub _addHostReal {
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $address;
    my ($hostReal, $hostname1, $aliases, $addrtype, $length, @addrs, @addrs1);

    # get detailed information about this host &
    # check if host exists at all
    unless ( ($hostReal, $aliases, $addrtype, $length, @addrs) = gethostbyname($host)) {
#        return;
        $hostReal = $host;
    }

    $self->{HOSTS}->{$host} = {};
    $self->{HOSTS}->{$host}->{REALHOST} = $hostReal;

    # add host to list of real hosts
    $self->{REALHOSTS}->{$hostReal} = {} if (!exists $self->{REALHOSTS}->{$hostReal});

    # we're dealing with alias here
    if ($hostReal ne $host) {
        $self->{HOSTS}->{$host}->{ADDRESS} = $host;
        $self->{HOSTS}->{$host}->{ALIAS} = $hostReal;

        # Add real host
        $self->{REALHOSTS}->{$hostReal}->{ALIASES}->{$host} = {};

        $self->verbose ("Found alias: $host, real hostname: $hostReal");
    } else {
        # here we use hostname for address field only if host has
        # load-balanced nodes
        $self->verbose ("Found host: $host.");
        if ($#addrs) {
            $self->{HOSTS}->{$host}->{ADDRESS} = $host;
        } else {
            $self->{HOSTS}->{$host}->{ADDRESS} = join ('.', unpack('C4', $addrs[0]));
        }
    }

    # if there are load-balanced nodes add them to list
    # of aliases, use their IP addresses for address field
    if ($#addrs && ! exists $self->{REALHOSTS}->{$hostReal}->{LBNODES}) {
        foreach my $addr (@addrs) {
            if (($hostname1, $aliases, $addrtype, $length, @addrs1) = gethostbyaddr($addr, AF_INET)) {
                $self->{REALHOSTS}->{$hostReal}->{LBNODES}->{$hostname1}->{ADDRESS} = join ('.', unpack('C4', $addr));
                $self->verbose("  Found LB node: $hostname1.");
            }
        }
    }

    1;
}

sub addHost
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $res;
    
    $self->_addHostReal($host) if (! exists $self->{HOSTS}->{$host});
}

sub addService
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;

    # host is in HOSTS, add service to REALHOSTS
    if (exists $self->{HOSTS}->{$host}) {
        if (! exists $self->{HOSTS}->{$host}->{SERVICES}->{$service}) {
            $self->{HOSTS}->{$host}->{SERVICES}->{$service} = {};
        }
        
        my $realHost = $self->{HOSTS}->{$host}->{REALHOST};
        if (! exists $self->{REALHOSTS}->{$realHost}->{SERVICES}->{$service}) {
            $self->{REALHOSTS}->{$realHost}->{SERVICES}->{$service} = {};
        }
    }
    # host is only in REALHOSTS, add service to REALHOSTS & to all ALIASES
    # TODO:
    #  what if the alias is added afterwards? (this should probably be handled
    #  afterwards in consistency check)
    elsif (exists $self->{REALHOSTS}->{$host}) {
        if (! exists $self->{REALHOSTS}->{$host}->{SERVICES}->{$service}) {
            $self->{REALHOSTS}->{$host}->{SERVICES}->{$service} = {};
        }
        if ( exists $self->{REALHOSTS}->{$host}->{ALIASES}) {
            foreach my $hostname (keys %{$self->{REALHOSTS}->{$host}->{ALIASES}}) {
                if (! exists $self->{HOSTS}->{$hostname}->{SERVICES}->{$service}) {
                    $self->{HOSTS}->{$hostname}->{SERVICES}->{$service} = {};
                }
            }
        }
    }
    # host doesn't exist, this is not allowed
    else {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    1;
}

sub addVO
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;
    my $vo = shift;
    
    # host is in HOSTS, add service to REALHOSTS
    if (exists $self->{HOSTS}->{$host}) {
        # if service is not on the host return error
        if (! exists $self->{HOSTS}->{$host}->{SERVICES}->{$service} ) {
            $self->warning ("Service $service is not present on host $host!");
            return;
        }
        
        $self->{HOSTS}->{$host}->{SERVICES}->{$service}->{VOS}->{$vo} = 0;
        
        my $realHost = $self->{HOSTS}->{$host}->{REALHOST};
        $self->{REALHOSTS}->{$realHost}->{SERVICES}->{$service}->{VOS}->{$vo} = 0;
    }
    # host is only in REALHOSTS, add VO to REALHOSTS & to all ALIASES that have service
    # TODO:
    #  what if the alias is added afterwards? (this should probably be handled
    #  afterwards in consistency check)
    elsif (exists $self->{REALHOSTS}->{$host}) {
        if (! exists $self->{REALHOSTS}->{$host}->{SERVICES}->{$service} ) {
            $self->warning ("Service $service is not present on host $host!");
            return;
        }
        
        $self->{REALHOSTS}->{$host}->{SERVICES}->{$service}->{VOS}->{$vo} = 0;

        if ( exists $self->{REALHOSTS}->{$host}->{ALIASES}) {
            foreach my $hostname (keys %{$self->{REALHOSTS}->{$host}->{ALIASES}}) {
                if ( exists $self->{HOSTS}->{$hostname}->{SERVICES}->{$service}) {
                    $self->{HOSTS}->{$hostname}->{SERVICES}->{$service}->{VOS}->{$vo} = 0;
                }
            }
        }
    }
    # host doesn't exist, this is not allowed
    else {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }    

    1;
}

# remote metrics are not propagated to REALHOSTS
sub addRemoteMetric
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift;
    my $remoteService = shift;
    my $url = shift;
    my $docUrl = shift;
    my $vo = shift;

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{HOSTS}->{$host}->{METRICS}->{$metric} = {};
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{TYPE} = "remote";
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{REMOTESERVICE} = $remoteService;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{URL} = $url;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{DOCURL} = $docUrl;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{VO} = $vo;

    $self->{METRIC_COUNT}++;
    
    1;
}

# remote metrics are not propagated to REALHOSTS
sub addRemoteMetricLong {
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift;
    my $remoteService = shift;
    my $config = shift;
    my $url = shift;
    my $docUrl = shift;
    my $vo = shift;
    my $dependencies = shift;

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{HOSTS}->{$host}->{METRICS}->{$metric} = {};
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{TYPE} = "remote";
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{REMOTESERVICE} = $remoteService;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{CONFIG} = $config;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{URL} = $url;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{DOCURL} = $docUrl;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{VO} = $vo;
    $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{DEPENDENCIES} = $dependencies;
    
    $self->{METRIC_COUNT}++;
    
    1;
}


# local metrics are stored in REALHOSTS; HOSTS contains only references
sub addLocalMetric
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift;
    my $service = shift || "Undefined";
    my $probe = shift;
    my $config = shift;
    my $attributes = shift;
    my $parameters = shift;
    my $fileAttributes = shift;
    my $fileParameters = shift;
    my $dependencies = shift;
    my $flags = shift;
    my $parent = shift;
    my $docUrl = shift;
    my $vo = shift;
    my $voFqan = shift || '_ALL_';

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    my $realHost = $self->{HOSTS}->{$host}->{REALHOST};

    if (exists $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}) {
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{SERVICES}->{$service} = 1;
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{VOS}->{$vo}->{$voFqan} = 1 if ($vo);
        $self->{HOSTS}->{$host}->{METRICS}->{$metric} = $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric};
        return 1;
    }

    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric} = {};
    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{TYPE} = "local";

    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{SERVICES}->{$service} = 1;
    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{PROBE} = $probe;
    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{DEPENDENCIES} = $dependencies;
    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{FLAGS} = $flags;
    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{DOCURL} = $docUrl;
    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{VOS}->{$vo}->{$voFqan} = 1 if ($vo);

    if ($self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{FLAGS}->{PASSIVE}) {
        if ($parent) {
            $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{PARENT} = $parent;
        } 
    } else {
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{CONFIG} = $config;
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{ATTRIBUTES} = $attributes;
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{PARAMETERS} = $parameters;
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{FILE_ATTRIBUTES} = $fileAttributes;
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{FILE_PARAMETERS} = $fileParameters;
    }

    $self->{HOSTS}->{$host}->{METRICS}->{$metric} = $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric};
    
    $self->{METRIC_COUNT}++;

    1;
}

# LB nodes are stored only in REALHOSTS
sub addLBNode
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $lbnode = shift || return;
    my $realHost;
    my $addr;
    
    if (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } elsif (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } else {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }
    
    unless ($addr = scalar gethostbyname($lbnode)) {
        $self->error("Invalid LB node hostname: $lbnode.");
        return;
    }

    $self->{REALHOSTS}->{$realHost}->{LBNODES}->{$lbnode}->{ADDRESS} = inet_ntoa($addr);
    
    1;
}

sub addContact
{
    my $self = shift;

    $self->debugSub(@_);

    my $value = shift || return;
    my $enabled = shift || 0;

    $self->{CONTACTS}->{$value} = $enabled;

    1;
}

sub addVoFqan
{
    my $self = shift;

    $self->debugSub(@_);

    my $vo = shift || return;
    my $voFqan = shift || return;

    $self->{VO_FQANS}->{$vo}->{$voFqan} = 1;

    1;
}

sub addUser
{
    my $self = shift;

    $self->debugSub(@_);

    my $dn = shift || return;
    my $name = shift || return;
    my $email = shift || return;

    $self->{USERS}->{$dn} = {EMAIL => $email, NAME => $name};

    1;
}

# Contacts are stored in REALHOSTS only
sub addHostContact
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $value = shift || return;
    my $enabled = shift || 0;

    if (exists $self->{CONTACTS}->{$value})
    {
        $self->warning ("Contact is already in site contacts.");
        return;
    }

    if (exists $self->{REALHOSTS}->{$host}) {
        $self->{REALHOSTS}->{$host}->{CONTACTS}->{$value} = $enabled;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        my $realHost = $self->{HOSTS}->{$host}->{REALHOST};
        $self->{REALHOSTS}->{$realHost}->{CONTACTS}->{$value} = $enabled;
    } else {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    1;
}

# Contacts are stored in HOSTS only
sub addServiceContact
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;
    my $value = shift || return;

    if (exists $self->{CONTACTS}->{$value})
    {
        $self->warning ("Contact is already in site contacts.");
        return;
    }

    if (exists $self->{HOSTS}->{$host} ) {
        my $realHost = $self->{HOSTS}->{$host}->{REALHOST};
        if (exists $self->{REALHOSTS}->{$realHost}->{CONTACTS}->{$value}) {
            $self->warning ("Contact is already in host contacts.");
            return;
        }
        $self->{HOSTS}->{$host}->{SERVICE_CONTACTS}->{$service}->{$value} = 1;
    } else {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    1;
}

# Contacts are stored in REALHOSTS only
sub addServiceFlavourContact
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;
    my $value = shift || return;
    my $enabled = shift || 0;

    if (exists $self->{CONTACTS}->{$value})
    {
        $self->warning ("Contact is already in site contacts.");
        return;
    }

    if (exists $self->{HOSTS}->{$host} ) {
        my $realHost = $self->{HOSTS}->{$host}->{REALHOST};
        if (exists $self->{REALHOSTS}->{$realHost}->{CONTACTS}->{$value}) {
            $self->warning ("Contact is already in host contacts.");
            return;
        }
        $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}->{$service}->{$value} = $enabled;
    } else {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    1;
}

sub addRemoteService
{
    my $self = shift;

    $self->debugSub(@_);

    my $value = shift || return;

    $self->{REMOTESERVICES}->{$value} = 1;

    1;
}

# Remove methods

# host is removed from REALHOSTS only in case it doesn't have any aliases left
sub _removeHostReal ($$$)
{
    my $self = shift;
    
    $self->debugSub(@_);

    my $host = shift;
    my $hostAlias = shift;

    # check if host still has some aliases
    if (exists $self->{REALHOSTS}->{$host}->{ALIASES}) {
        delete $self->{REALHOSTS}->{$host}->{ALIASES}->{$hostAlias};

        if ( ! %{$self->{REALHOSTS}->{$host}->{ALIASES}} ) {
            delete $self->{REALHOSTS}->{$host};
        }
    } else {
        delete $self->{REALHOSTS}->{$host};
    }
}

sub removeHost
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->_removeHostReal($self->{HOSTS}->{$host}->{REALHOST}, $host);
    delete $self->{HOSTS}->{$host};

    1;
}

# remove service from REALHOST only
sub _removeServiceReal
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $service = shift || return;

    if ( exists $self->{REALHOSTS}->{$host}->{ALIASES}) {
        foreach my $hostname (keys %{$self->{REALHOSTS}->{$host}->{ALIASES}}) {
            delete $self->{HOSTS}->{$hostname}->{SERVICES}->{$service};
        }
    }

    delete $self->{REALHOSTS}->{$host}->{SERVICES}->{$service};
}

sub removeService
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $service = shift  || return;
    my $hostOnly = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            delete $self->{HOSTS}->{$hostname}->{SERVICES}->{$service};
            $self->_removeServiceReal($self->{HOSTS}->{$hostname}->{REALHOST}, $service) if (!$hostOnly);
        }
    } else {
        if (exists $self->{HOSTS}->{$host} ) {
            delete $self->{HOSTS}->{$host}->{SERVICES}->{$service};
            $self->_removeServiceReal($self->{HOSTS}->{$host}->{REALHOST}, $service) if (!$hostOnly);
        } elsif (exists $self->{REALHOSTS}->{$host}) {
            $self->_removeServiceReal($host, $service);
        } else {
            $self->warning ("Host $host is not in the list of hosts on site!");
            return;
        }
    }

    1;
}

# remove metrics from REALHOST only
sub _removeMetricReal
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $service = shift;
    my $metric = shift;

    if ( exists $self->{REALHOSTS}->{$host}->{ALIASES}) {
        foreach my $hostname (keys %{$self->{REALHOSTS}->{$host}->{ALIASES}}) {
            if (!$service || (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric} && exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}->{SERVICES}->{$service})) {
                delete $self->{HOSTS}->{$hostname}->{METRICS}->{$metric};
            }
        }
    }

    if (!$service || (exists $self->{REALHOSTS}->{$host}->{METRICS}->{$metric} && exists $self->{REALHOSTS}->{$host}->{METRICS}->{$metric}->{SERVICES}->{$service})) {
        delete $self->{REALHOSTS}->{$host}->{METRICS}->{$metric};
    }
}

sub removeMetric
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $service = shift;
    my $metric = shift || return;
    my $hostOnly = shift;

    # if host is undefined, remove metric from all hosts
    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            # if service is defined check if host has the service first
            if (!$service || (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric} && exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}->{SERVICES}->{$service})) {
                delete $self->{HOSTS}->{$hostname}->{METRICS}->{$metric};
            }
            # if flag hostOnly is switched on don't remove metrics from other aliases
            $self->_removeMetricReal($self->{HOSTS}->{$hostname}->{REALHOST}, $service, $metric) if (!$hostOnly);
        }
    } else {
        # host is defined, check if it exists
        if (exists $self->{HOSTS}->{$host} ) {
            if (!$service || (exists $self->{HOSTS}->{$host}->{METRICS}->{$metric} && exists $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{SERVICES}->{$service})) {
                delete $self->{HOSTS}->{$host}->{METRICS}->{$metric};
            }
            $self->_removeMetricReal($self->{HOSTS}->{$host}->{REALHOST}, $service, $metric) if (!$hostOnly);
        }
        # check if real host exists
        elsif (exists $self->{REALHOSTS}->{$host}) {
            $self->_removeMetricReal($host, $service, $metric);
        } else {
            $self->warning ("Host $host is not in the list of hosts on site!");
            return;
        }
    }

    1;
}



sub removeLBNode
{
    my $self = shift;
    
    $self->debugSub(@_);

    my $host = shift || return;
    my $lbnode = shift || return;
    my $realHost;
    
    if (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } elsif (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    delete $self->{REALHOSTS}->{$realHost}->{LBNODES}->{$lbnode};

    1;
}

sub removeContact
{
    my $self = shift;

    $self->debugSub(@_);

    my $value = shift || return;

    delete $self->{CONTACTS}->{$value};

    1;
}

# Accessor methods

sub siteName
{
    my $self = shift;

    $self->debugSub(@_);

    my $value = shift;

    $self->{SITENAME} = $value if (defined $value);
    $self->{SITENAME};
}

sub siteROC
{
    my $self = shift;

    $self->debugSub(@_);

    my $value = shift;

    $self->{ROC} = $value if (defined $value);
    $self->{ROC};
}

sub siteLDAP
{
    my $self = shift;
    
    $self->debugSub(@_);

    my $value = shift;

    $self->{LDAP_ADDRESS} = $value if (defined $value);
    $self->{LDAP_ADDRESS};
}

sub siteCountry
{
    my $self = shift;

    $self->debugSub(@_);

    my $value = shift;

    $self->{COUNTRY} = $value if (defined $value);
    $self->{COUNTRY};
}

sub addSiteGrid
{
    my $self = shift;

    $self->debugSub(@_);

    my $value = shift || return;

    $self->{GRIDS}->{$value} = 1;
    $self->{GRIDS};
}

# global attributes
sub globalAttribute
{
    my $self = shift;

    $self->debugSub(@_);

    my $attribute = shift || return;
    my $value = shift;

    $self->{ATTRIBUTES}->{$attribute}->{VALUE} = $value if (defined $value);
    $self->{ATTRIBUTES}->{$attribute}->{VALUE};
}


# attributes are stored only in REALHOSTS
sub hostAttribute
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $attribute = shift || return;
    my $value = shift;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES}->{$attribute}->{VALUE} = $value if (defined $value);
    if (!exists $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES}->{$attribute}->{VALUE}) {
        return $self->globalAttribute($attribute);
    } else {
        return $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES}->{$attribute}->{VALUE};
    }
}

# attributes are stored only in REALHOSTS
sub globalAttributeVO
{
    my $self = shift;

    $self->debugSub(@_);

    my $attribute = shift || return;
    my $vo = shift || return;
    my $value = shift;

    $self->{ATTRIBUTES}->{$attribute}->{VOS}->{$vo} = $value if (defined $value);
    $self->{ATTRIBUTES}->{$attribute}->{VOS}->{$vo};
}

# attributes are stored only in REALHOSTS
sub hostAttributeVO
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $attribute = shift;
    my $vo = shift;
    my $value = shift;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES}->{$attribute}->{VOS}->{$vo} = $value if (defined $value);

    if (!exists $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES}->{$attribute}->{VOS}->{$vo}) {
        return $self->globalAttributeVO($attribute,$vo);
    } else {
        return $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES}->{$attribute}->{VOS}->{$vo};
    }
}

# attributes are stored only in REALHOSTS
sub addHostAttributeArray
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $attribute = shift || return;
    my $value = shift || return;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES_ARRAY}->{$attribute}->{VALUE}->{$value} = 1;
}

# attributes are stored only in REALHOSTS
sub addHostAttributeArrayVO
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $attribute = shift || return;
    my $vo = shift || return;
    my $value = shift || return;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES_ARRAY}->{$attribute}->{VOS}->{$vo}->{$value} = 1 if (defined $value);
}

# Metric methods

sub _metricField
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift;
    my $attr = shift;
    my $value = shift;

    # host is in HOSTS
    if (exists $self->{HOSTS}->{$host}) {
        #my $realHost = $self->{HOSTS}->{$host}->{REALHOST};
        if (exists $self->{HOSTS}->{$host}->{METRICS}->{$metric})
        {
            #$self->{HOSTS}->{$host}->{METRICS}->{$metric}->{$attr} = $value if (defined $value);
            return $self->{HOSTS}->{$host}->{METRICS}->{$metric}->{$attr};
        }
        #elsif (exists $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric})
        #{
        #    $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{$attr} = $value if (defined $value);
        #    return $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{$attr};
        #}
        else
        {
            $self->warning ("Metric $metric is not present on host $host!");
            return;
        }
    }
    # host is only in REALHOSTS
    elsif (exists $self->{REALHOSTS}->{$host})
    {
        if (exists $self->{REALHOSTS}->{$host}->{METRICS}->{$metric})
        {
            #$self->{REALHOSTS}->{$host}->{METRICS}->{$metric}->{$attr} = $value if (defined $value);
            return $self->{REALHOSTS}->{$host}->{METRICS}->{$metric}->{$attr};
        }
        else
        {
            $self->warning ("Metric $metric is not present on host $host!");
            return;
        }
    }
    # host doesn't exist, this is not allowed
    else {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }
}

sub _metricHashField
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $attr = shift || return;
    my $flag = shift || return;
    my $value = shift;

    my $flags = $self->_metricField ($host, $metric, $attr);

    return unless ($flags);
    if (defined $value) {
        $flags->{$flag} = $value;
        return $flags->{$flag};
    }
    return $flags->{$flag} if (exists $flags->{$flag});
}

sub metricType
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "TYPE", $value);
}

# metricDocUrl can belong to both remote and local service so we need to check
# both HOSTS AND REALHOSTS
sub metricDocUrl
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "DOCURL", $value);
}

sub metricProbe
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;
    
    $self->_metricField ($host, $metric, "PROBE", $value);
}

sub metricRemoteService
{
    my $self = shift;
    
    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "REMOTESERVICE", $value);
}

sub metricUrl
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "URL", $value);
}

sub metricParent
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "PARENT", $value);
}

sub metricVo
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "VO", $value);
}

# hash fields
# if value is set it will reset the whole hash
# returns keys of hash

#these return keys:
# metricServices
# metricVoFqans
#
#return hash:
# metricConfig
# metricAttributes
# metricParameters
# metricDependencies

sub metricServices
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    my $res = $self->_metricField ($host, $metric, "SERVICES", $value);

    if (ref $res eq "HASH") {
        return keys %$res;
    } else {
        return ();
    }
}

sub metricVoFqans
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;

    my $res = $self->_metricField ($host, $metric, "VOS");

    if (ref $res eq "HASH") {
        return $res;
    } else {
        return {};
    }
}

sub addMetricVoFqans
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $vo = shift || return;    
    my $voFqan = shift || '_ALL_';
    
    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning ("Host $host is not in the list of hosts on site!");
        return;
    }

    my $realHost = $self->{HOSTS}->{$host}->{REALHOST};

    if (exists $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}) {
        $self->{REALHOSTS}->{$realHost}->{METRICS}->{$metric}->{VOS}->{$vo}->{$voFqan} = 1;
        return 1;
    }  else {
        $self->warning ("Metric $metric doesn't exist on host $host!");
        return;
    }
}


sub metricConfig
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "CONFIG", $value);
}

sub defaultConfig
{
    my $self = shift;

    $self->debugSub(@_);

    my $config = {
        path => '/usr/lib64/nagios/plugins',
        interval => 60,
        timeout => 60,
        retryInterval => 5,
        maxCheckAttempts => 3
    };
    
    return $config;
}

sub metricConfigValue
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift || return;
    my $conf = shift || return;
    my $value = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            if (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}) {
                $self->_metricHashField ($hostname, $metric, "CONFIG", $conf, $value);
            }
        }
        if (exists $self->{METRICS}->{$metric}) {
            $self->{METRICS}->{$metric}->{CONFIG}->{$conf} = $value;
        }
    } else {
        $self->_metricHashField ($host, $metric, "CONFIG", $conf, $value);
    }
}

sub metricAttributes
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "ATTRIBUTES", $value);
}

sub metricAttribute
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift || return;
    my $attr = shift || return;    
    my $value = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            if (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}) {
                $self->_metricHashField ($hostname, $metric, "ATTRIBUTES", $attr, $value);
            }
        }
        if (exists $self->{METRICS}->{$metric}) {
            $self->{METRICS}->{$metric}->{ATTRIBUTES}->{$attr} = $value;
        }
    } else {
        $self->_metricHashField ($host, $metric, "ATTRIBUTES", $attr, $value);
    }
}

sub metricFileAttributes
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "FILE_ATTRIBUTES", $value);
}

sub metricFileAttribute
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift || return;
    my $attr = shift || return;
    my $value = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            if (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}) {
                $self->_metricHashField ($hostname, $metric, "FILE_ATTRIBUTES", $attr, $value);
            }
        }
        if (exists $self->{METRICS}->{$metric}) {
            $self->{METRICS}->{$metric}->{FILE_ATTRIBUTES}->{$attr} = $value;
        }
    } else {
        $self->_metricHashField ($host, $metric, "FILE_ATTRIBUTES", $attr, $value);
    }
}

sub metricParameters
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "PARAMETERS", $value);
}

sub metricParameter
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift || return;
    my $param = shift || return;    
    my $value = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            if (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}) {
                $self->_metricHashField ($hostname, $metric, "PARAMETERS", $param, $value);
            }
        }
        if (exists $self->{METRICS}->{$metric}) {
            $self->{METRICS}->{$metric}->{PARAMETERS}->{$param} = $value;
        }
    } else {
        $self->_metricHashField ($host, $metric, "PARAMETERS", $param, $value);
    }
}

sub metricFileParameters
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "FILE_PARAMETERS", $value);
}

sub metricFileParameter
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift || return;
    my $param = shift || return;
    my $value = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            if (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}) {
                $self->_metricHashField ($hostname, $metric, "FILE_PARAMETERS", $param, $value);
            }
        }
        if (exists $self->{METRICS}->{$metric}) {
            $self->{METRICS}->{$metric}->{FILE_PARAMETERS}->{$param} = $value;
        }
    } else {
        $self->_metricHashField ($host, $metric, "FILE_PARAMETERS", $param, $value);
    }
}

sub metricDependencies
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $value = shift;

    $self->_metricField ($host, $metric, "DEPENDENCIES", $value);
}

sub metricDependency
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift || return;
    my $dep = shift || return;
    my $value = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            if (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}) {
                $self->_metricHashField ($hostname, $metric, "DEPENDENCIES", $dep, $value);
            }
        }
        if (exists $self->{METRICS}->{$metric}) {
            $self->{METRICS}->{$metric}->{DEPENDENCIES}->{$dep} = $value;
        }
    } else {
        $self->_metricHashField ($host, $metric, "DEPENDENCIES", $dep, $value);
    }
}

sub metricFlag
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift;
    my $metric = shift || return;
    my $flag = shift || return;
    my $value = shift;

    if (!$host) {
        foreach my $hostname (keys %{$self->{HOSTS}}) {
            if (exists $self->{HOSTS}->{$hostname}->{METRICS}->{$metric}) {
                $self->_metricHashField ($hostname, $metric, "FLAGS", $flag, $value);
            }
        }
        if (exists $self->{METRICS}->{$metric}) {
            $self->{METRICS}->{$metric}->{FLAG}->{$flag} = $value;
        }
    } else {
        $self->_metricHashField ($host, $metric, "FLAGS", $flag, $value);
    }
}

sub parent
{
    my $self = shift;

    $self->debugSub(@_);

    if (!exists $self->{PARENT}) {
        return;
    }

    $self->{PARENT};
}

# read-only
sub hostAddress
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    
    if (!exists $self->{HOSTS}->{$host} ) {
        $self->error ("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{HOSTS}->{$host}->{ADDRESS};    
}

sub realHost
{
    my $self = shift;
    
    $self->debugSub(@_);

    my $host = shift || return;
    
    if (!exists $self->{HOSTS}->{$host} ) {
        $self->error ("Host $host is not in the list of hosts on site!");
        return;
    }
    
    $self->{HOSTS}->{$host}->{REALHOST};
}

sub hostAlias
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->error ("Host $host is not in the list of hosts on site!");
        return;
    }

    $self->{HOSTS}->{$host}->{ALIAS};
}

sub LBNodeAddress
{
    my $self = shift;
    
    $self->debugSub(@_);

    my $host = shift || return;
    my $lbnode = shift || return;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }
    
    if (exists $self->{REALHOSTS}->{$realHost}->{LBNODES}) {
        return $self->{REALHOSTS}->{$realHost}->{LBNODES}->{$lbnode}->{ADDRESS};
    }
}

sub userName
{
    my $self = shift;

    $self->debugSub(@_);

    my $user = shift || return;

    if (!exists $self->{USERS}->{$user} ) {
        $self->error ("User $user is not in the list of users on site!");
        return;
    }

    $self->{USERS}->{$user}->{NAME};
}

sub userEmail
{
    my $self = shift;

    $self->debugSub(@_);

    my $user = shift || return;

    if (!exists $self->{USERS}->{$user} ) {
        $self->error ("User $user is not in the list of users on site!");
        return;
    }

    $self->{USERS}->{$user}->{EMAIL};
}

# iterator methods

sub getHosts
{
    my $self = shift;

    $self->debugSub(@_);

    if (exists $self->{HOSTS}) {
        return keys %{$self->{HOSTS}};
    } else {
        return ();
    }
}

sub getRealHosts
{
    my $self = shift;

    $self->debugSub(@_);

    if (exists $self->{REALHOSTS}) {
        return keys %{$self->{REALHOSTS}};
    } else {
        return ();
    }
}

sub getServices
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;

    if (exists $self->{HOSTS}->{$host}) {
        return keys %{$self->{HOSTS}->{$host}->{SERVICES}};
    } else {
        return ();
    }
}

sub getRealServices
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;

    if (exists $self->{REALHOSTS}->{$host}) {
        return keys %{$self->{REALHOSTS}->{$host}->{SERVICES}};
    } else {
        return ();
    }
}

sub getVOsByHostService
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();
    my $service = shift || return ();

    if (exists $self->{HOSTS}->{$host}) {
        if (exists $self->{HOSTS}->{$host}->{SERVICES}->{$service}) {
            return keys %{$self->{HOSTS}->{$host}->{SERVICES}->{$service}->{VOS}};
        } else {
            return ();
        }
    } else {
        return ();
    }
}

sub getMetrics
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();

    if (exists $self->{HOSTS}->{$host}) {
        return keys %{$self->{HOSTS}->{$host}->{METRICS}};
    } else {
        return ();
    }
}

sub getLocalMetrics
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();

    if (exists $self->{HOSTS}->{$host}) {
        my @metrics;
        foreach my $metric ( keys %{$self->{HOSTS}->{$host}->{METRICS}}) {
            if ($self->{HOSTS}->{$host}->{METRICS}->{$metric}->{TYPE} eq 'local') {
                push @metrics, $metric;
            }
        }
        return @metrics;
    } else {
        return;
    }
}

sub getNativeMetrics
{
    my $self = shift;

    $self->getLocalMetrics(@_);
}

sub getRemoteMetrics
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();

    if (exists $self->{HOSTS}->{$host}) {
        my @metrics;
        foreach my $metric ( keys %{$self->{HOSTS}->{$host}->{METRICS}}) {
            if ($self->{HOSTS}->{$host}->{METRICS}->{$metric}->{TYPE} eq 'remote') {
                push @metrics, $metric;
            }
        }
        return @metrics;
    } else {
        return ();
    }
}

sub getRealMetrics
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();

    if (exists $self->{REALHOSTS}->{$host}) {
        return keys %{$self->{REALHOSTS}->{$host}->{METRICS}};
    } else {
        return ();
    }
}

sub getRealLocalMetrics
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();

    if (exists $self->{REALHOSTS}->{$host}) {
        my @metrics;
        foreach my $metric ( keys %{$self->{REALHOSTS}->{$host}->{METRICS}}) {
            if ($self->{REALHOSTS}->{$host}->{METRICS}->{$metric}->{TYPE} eq 'local') {
                push @metrics, $metric;
            }    
        }
        return @metrics;
    } else {
        return ();
    }
}

sub getRealNativeMetrics
{
    my $self = shift;

    $self->getRealLocalMetrics(@_);
}

sub getLBNodes
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }
    
    if (exists $self->{REALHOSTS}->{$realHost}->{LBNODES}) {
        return keys %{$self->{REALHOSTS}->{$realHost}->{LBNODES}};
    } else {
        return ();
    }
}

sub getAliases
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }

    if (exists $self->{REALHOSTS}->{$realHost}->{ALIASES}) {
        return keys %{$self->{REALHOSTS}->{$realHost}->{ALIASES}};
    } else {
        return ();
    }
}

sub getContacts
{
    my $self = shift;

    $self->debugSub(@_);

    if (exists $self->{CONTACTS}) {
        return keys %{$self->{CONTACTS}};
    } else {
        return ();
    }
}

sub isContactEnabled
{
    my $self = shift;

    $self->debugSub(@_);

    my $contact = shift || return 0;

    if (exists $self->{CONTACTS}) {
        if (exists $self->{CONTACTS}->{$contact}) {
            return $self->{CONTACTS}->{$contact};
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

sub getHostProfiles {
    my $self = shift;

    $self->debugSub(@_);
    
    my $host = shift || return;

    return $self->{HOSTS}->{$host}->{PROFILES};
}

sub getProfiles
{
    my $self = shift;

    $self->debugSub(@_);

    if (exists $self->{PROFILES}) {
        return keys %{$self->{PROFILES}};
    } else {
        return ();
    }
}

sub getVoFqans
{
    my $self = shift;
    my $vo = shift or return ();

    $self->debugSub(@_);

    if (exists $self->{VO_FQANS}->{$vo}) {
        return keys %{$self->{VO_FQANS}->{$vo}};
    } else {
        return ();
    }
}

sub getUsers
{
    my $self = shift;

    $self->debugSub(@_);

    if (exists $self->{USERS}) {
        return keys %{$self->{USERS}};
    } else {
        return ();
    }
}

sub getHostContacts
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }

    if (exists $self->{REALHOSTS}->{$realHost}->{CONTACTS}) {
        return keys %{$self->{REALHOSTS}->{$realHost}->{CONTACTS}};
    } else {
        return ();
    }
}

sub isHostContactEnabled
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return 0;
    my $contact = shift || return 0;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return 0;
    }

    if (exists $self->{REALHOSTS}->{$realHost}->{CONTACTS}) {
        if (exists $self->{REALHOSTS}->{$realHost}->{CONTACTS}->{$contact}) {
            return $self->{REALHOSTS}->{$realHost}->{CONTACTS}->{$contact};
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

sub getServiceContactsServices
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }

    if (exists $self->{HOSTS}->{$host}->{SERVICE_CONTACTS}) {
        return keys %{$self->{HOSTS}->{$host}->{SERVICE_CONTACTS}};
    } else {
        return ();
    }
}

sub getServiceContacts
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();
    my $service = shift || return ();

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }

    if (exists $self->{HOSTS}->{$host}->{SERVICE_CONTACTS} && exists $self->{HOSTS}->{$host}->{SERVICE_CONTACTS}->{$service}) {
        return keys %{$self->{HOSTS}->{$host}->{SERVICE_CONTACTS}->{$service}};
    } else {
        return ();
    }
}

sub getServiceFlavourContactsServiceFlavours
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }

    if (exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}) {
        return keys %{$self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}};
    } else {
        return ();
    }
}

sub getServiceFlavourContacts
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();
    my $service = shift || return ();

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }

    if (exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS} && exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}->{$service}) {
        return keys %{$self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}->{$service}};
    } else {
        return ();
    }    
}

sub isServiceFlavourContactEnabled
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return ();
    my $service = shift || return ();
    my $contact = shift || return 0;

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning("Host $host is not in the list of hosts on site!");
        return ();
    }
    
    if (exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS} && exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}->{$service}) {
        if (exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}->{$service}->{$contact}) {
            return $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}->{$service}->{$contact};
        } else {
            return 0;
        }
    } else {
        return 0;
    }    
}

sub getRemoteServices
{
    my $self = shift;

    $self->debugSub(@_);

    if (exists $self->{REMOTESERVICES}) {
        return keys %{$self->{REMOTESERVICES}};
    } else {
        return ();    
    }
}

sub getGrids
{
    my $self = shift;

    $self->debugSub(@_);

    if (exists $self->{GRIDS}) {
        return keys %{$self->{GRIDS}};
    } else {
        return ();
    }
}

# check methods

sub hasHost
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $hosts;

    return exists $self->{HOSTS}->{$host};
}

sub hasRealHost
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $hosts;

    return exists $self->{REALHOSTS}->{$host};

}

sub hasService
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;

    if (exists $self->{HOSTS}->{$host} ) {
        return exists $self->{HOSTS}->{$host}->{SERVICES}->{$service};
    }
}

sub hasRealService
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;

    if (exists $self->{REALHOSTS}->{$host}) {
        return exists $self->{REALHOSTS}->{$host}->{SERVICES}->{$service};
    }
}

sub hasAttribute {
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $attr = shift || return;
    my $realHost;

    if (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } elsif (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } else {
        $self->error("Host $host is not in the list of hosts on site!");
        return;
    }

    return (exists $self->{REALHOSTS}->{$realHost}->{ATTRIBUTES}->{$attr}->{VALUE} || exists $self->{ATTRIBUTES}->{$attr}->{VALUE});
}

sub hasContacts
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    return (exists $self->{REALHOSTS}->{$realHost}->{CONTACTS});
}

sub hasProfile
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $profile = shift || return;

    return (exists $self->{HOSTS}->{$host}->{PROFILES}->{$profile} ||  $self->{PROFILES}->{$profile});
}

sub hasServiceContacts
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    return (exists $self->{HOSTS}->{$host}->{SERVICE_CONTACTS} && exists $self->{HOSTS}->{$host}->{SERVICE_CONTACTS}->{$service});
}

sub hasServiceFlavourContacts
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $service = shift || return;

    if (!exists $self->{HOSTS}->{$host} ) {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    return (exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS} && exists $self->{HOSTS}->{$host}->{SERVICE_FLAVOUR_CONTACTS}->{$service});
}

sub hasLBNodes
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $realHost;

    if (exists $self->{REALHOSTS}->{$host}) {
        $realHost = $host;
    } elsif (exists $self->{HOSTS}->{$host} ) {
        $realHost = $self->{HOSTS}->{$host}->{REALHOST};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }
    
    return (exists $self->{REALHOSTS}->{$realHost}->{LBNODES});
}

sub hasMetrics {
    my $self = shift;
    my $retVal;
    $self->debugSub(@_);

    $retVal = 1 if ($self->{METRIC_COUNT} > 0);

    $retVal;
}

sub hasMetricVoFqan {
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $vo = shift || return;
    my $voFqan = shift || return;
    # if voFqan is not default one, return false on empty list
    my $isDefault = shift;
    my $result;
    my $hostRef;
    
    unless (defined $isDefault) {
        $isDefault = 1;
    }

    if (exists $self->{HOSTS}->{$host}) {
        $hostRef = $self->{HOSTS}->{$host};
    } elsif (exists $self->{REALHOSTS}->{$host}) {
        $hostRef = $self->{REALHOSTS}->{$host};
    }

    return undef unless (defined $hostRef);

    return $isDefault unless exists $hostRef->{METRICS}->{$metric}->{VOS};

    return 1 if exists $hostRef->{METRICS}->{$metric}->{VOS}->{$vo}->{$voFqan};

    return $isDefault if exists $hostRef->{METRICS}->{$metric}->{VOS}->{$vo}->{'_ALL_'};
}

sub hasMetricVo {
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $vo = shift || return;
    $vo = lc($vo);
    my $result;
    my $hostRef;
    
    if (exists $self->{HOSTS}->{$host}) {
        $hostRef = $self->{HOSTS}->{$host};
    } elsif (exists $self->{REALHOSTS}->{$host}) {
        $hostRef = $self->{REALHOSTS}->{$host};
    }

    return 0 unless (defined $hostRef);

    return 1 unless ( exists $hostRef->{METRICS}->{$metric}->{VOS} );

    return exists $hostRef->{METRICS}->{$metric}->{VOS}->{$vo};
}

sub hasVO
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $vo = shift || return;
    my $metric = shift;
    my $result;
    my $hostRef;
    $vo = lc($vo);

    if (exists $self->{HOSTS}->{$host}) {
        $hostRef = $self->{HOSTS}->{$host};
    } elsif (exists $self->{REALHOSTS}->{$host}) {
        $hostRef = $self->{REALHOSTS}->{$host};
    }

    if (defined $hostRef) {
        my @searchArr;
        # if services have no VO assigned we assume that VO is supported
        # examples are: MON, BDII, Site-BDII

        if ($metric) {
            return 0 unless ($self->hasMetricVo($host, $metric, $vo));
        
            @searchArr = $self->metricServices($host, $metric);
        } else {
            @searchArr = keys %{$hostRef->{SERVICES}};
        }

        my $foundNoVO = 0;
        foreach my $service (@searchArr) {
            if (exists $hostRef->{SERVICES}->{$service}->{VOS}) {
                if (exists $hostRef->{SERVICES}->{$service}->{VOS}->{$vo}) {
                    $result = 1;
                    last;
                } else {
                    $foundNoVO = 1;
                }
            }
        }
        
        return ($result || !$foundNoVO);
    }
}

sub hasMetric
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metric = shift || return;
    my $types = shift;
    my $metrics;

    # check if host exists
    if (exists $self->{HOSTS}->{$host}) {
        $metrics = $self->{HOSTS}->{$host}->{METRICS};
    } elsif (exists $self->{REALHOSTS}->{$host} ) {
        $metrics = $self->{REALHOSTS}->{$host}->{METRICS};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    if ($types && ref $types eq "HASH") {
        return exists $metrics->{$metric} && exists $types->{$metrics->{$metric}->{TYPE}};
    } else {
        return exists $metrics->{$metric};
    }
}

sub hasMetricNRPEService
{
    my $self = shift;

    $self->debugSub(@_);

    my $host = shift || return;
    my $metrics;

    # check if host exists
    if (exists $self->{HOSTS}->{$host}) {
        $metrics = $self->{HOSTS}->{$host}->{METRICS};
    } elsif (exists $self->{REALHOSTS}->{$host} ) {
        $metrics = $self->{REALHOSTS}->{$host}->{METRICS};
    } else {
        $self->warning("Host $host is not in the list of hosts on site!");
        return;
    }

    foreach my $metricRef (values %{$metrics}) {
        if (exists $metricRef->{FLAGS}->{NRPE_SERVICE}) {
            return 1;
        }
    }
}

# consistency check

#sub _checkHostDependencies
#{
#    my $self = shift;
    
#    foreach my $metric (
#}

# iterate through REALHOSTS and clean up metrics with unsatisfied
# dependencies
#sub checkDependencies
#{
#    my $self = shift;

#    foreach my $host (keys %{$self->{REALHOSTS}})
#    {
#        $self->_checkHostDependencies($self->{REALHOSTS}->{$host}->{METRICS});
#    }
#}

=head1 NAME

NCG::SiteDB

=head1 DESCRIPTION

The NCG::SiteDB module encapsulates the structure containing information
about grid site, services & local/remote probes used
for monitoring.

Main component of NCG::SiteDB module is list of hosts which belong to site.
Internally NCG::SiteDB keeps two lists of hosts in order to handle properly
aliases and LB nodes:
- List HOSTS contains all hosts which are found by NCG::SiteInfo module
and for these hosts configuration is generated by NCG::ConfigGen. 
- List REALHOSTS contains list of real names of hosts in list HOSTS.

Structure is based on topology and probe description database.
Structure of HOSTS is following:
  $self->{HOSTS}
    - contains list of hosts on site
    - attributes:
      - ADDRESS: host address used for host check
      - ALIAS: alias is set to real hostname if host is an alias
      - REALHOST: real name of host (this is always set to name
      used in list REALHOSTS)

  $self->{HOSTS}->{$hostName}->{SERVICES}
    - contains list of services on host
    - services are interpreted as grid services in GOCDB (nodetypes)
    - examples: SRM, SE, CE, BDII

  $self->{HOSTS}->{$hostName}->{SERVICES}->{$serviceName}->{VOS}
    - contains list of VOs supported on service
    - this list is not mandatory (e.g. grids without VOs)

  $self->{HOSTS}->{$hostName}->{METRICS}
    - contains list of metrics on host
    - metrics are atomic checks
    - single service contains several metrics
    - examples: hr.srce.GridFTP-Transfer, ch.cern.LFC-Readdir
    - attributes:
      - TYPE: local|remote
      - DOCURL: URL with metric documentation
      - URL: URL with detailed output (remote only)
      - REMOTESERVICE: name of the remote service which performed
      remote check (remote only)
      - PROBE: executable (local only)
      - SERVICES: list of services to which metric belongs
      - CONFIG: configuration paramteres hash (local only)
      - ATTRIBUTES: attributes hash (local only)
                    value=parametername
      - PARAMETERS: parameters hash (local only)
                    parametername=[value]
      - FILE_ATTRIBUTES: attributes hash (local only)
                    value=parametername
      - FILE_PARAMETERS: parameters hash (local only)
                    parametername=[value]
      - DEPENDENCIES: array of metrics which metric depends on (local only)
      - PASSIVE: metric is part of a complex check, e.g. SAM tests (local only)
      - PARENT: name of the metric which is executing complex check (local only)
      - VO_FQANS: list of VOs of VO_FQANs for which metric should be executed

Structure of REALHOSTS is following:
  $self->{REALHOSTS}
    - contains list of hosts on site
    - attributes:
      - ADDRESS: host address used for host check

  $self->{REALHOSTS}->{$hostName}->{ATTRIBUTES}
    - contains list of attributes needed for metrics

  $self->{REALHOSTS}->{$hostName}->{ATTRIBUTES}->{$attribute}->{VOS}
    - contains list of attribute values for each supported

  $self->{REALHOSTS}->{$hostName}->{ALIASES}
    - contains list of aliases for the host

  $self->{REALHOSTS}->{$hostName}->{LBNODES}
    - contains list of load balancing nodes for the host

  $self->{REALHOSTS}->{$hostName}->{CONTACTS}
    - contains list of contact persons for host

(Following lists are the same as in list HOSTS with the difference
that memers are aggregated over all aliases)

  $self->{REALHOSTS}->{$hostName}->{SERVICES}
    - contains list of services aggregated over all aliases
    - attributes are the same as in HOSTS list

  $self->{REALHOSTS}->{$hostName}->{SERVICES}->{$serviceName}->{VOS}
    - contains list of VOs supported on service aggregated over all
    aliases
    - attributes are the same as in HOSTS list

  $self->{REALHOSTS}->{$hostName}->{METRICS}
    - contains list of local-ONLY metrics aggregated over all aliases
    - attributes are the same as in HOSTS list

Global attributes which can be used for any host are stored in:
  $self->{ATTRIBUTES}
When fetching attributes via hostAttribute method first hosts attributes
are checked and then global ones.

=head1 SYNOPSIS

  use NCG::SiteDB;

=cut

=head1 METHODS

=over

=item C<new>

  $site = NCG::SiteDB->new( $attr );

Creates new NCG instance.

=item C<addHost>

  $res = $site->addHost( $host );

Adds new host.

Result is 1 if operation is successful, 0 otherwise.

If $host is not alias, host is added to HOSTS and REALHOSTS.
If $host is alias, real hostname is added to REALHOSTS. 
If host has LB nodes, LB nodes are added to REALHOSTS.

=item C<addService>

  $res = $ncg->addService( $host, $service );

Adds new service to host. If host doesn't exist, method returns error.

Result is 1 if operation is successful, 0 otherwise.

Service is added to both HOSTS and REALHOSTS.
Services are added to REALHOST in order to generate
proper configuration for LB nodes.

=item C<addVO>

  $res = $ncg->addVO( $host, $service, $vo );

Adds new supported VO to service on host. If service on host doesn't exist,
method returns error.

Result is 1 if operation is successful, 0 otherwise.

VO is added to both HOSTS and REALHOSTS.

=item C<addLocalMetric>

  $res = $ncg->addLocalMetric( $host, $metric, $probe,
                               $config, $attributes, $parameters,
                               $fileAttributes, $fileParameters,
                               $dependencies, $flags, $parent, $docUrl);

Adds new local metric to host. If host doesn't exist, method returns error.

Parameters are:
    - $host: add metric to defined host
    - $metric: metric name
    - $probe: executable used for gathering metric
    - $config: configuration paramteres hash (name=>value)
    - $attributes: attributes hash (name=>value)
    - $parameters: parameters hash (name=>value)
    - $fileAttributes: attributes hash to be stored to file (name=>value)
    - $fileParameters: parameters hash to be stored to file (name=>value)
    - $dependencies: dependencies hash (parentMetric=>value); value is
    1 for host internal dependencies and 0 for external (e.g.
    GridProxy-Valid)
    - $flags: various metric flags hash (name=>value),
      currently supported flags:
      - PASSIVE: if defined, metric is part of a complex check
      - VO: defines if metric is VO dependent
      - NRPE: defines if metric should be executed on NRPE
      - NOLBNODE: defines if metric should be executed against LB nodes
      - PNP: generate action_url pointing to PNP data
      - SUDO: command is executed via sudo
      - NOHOSTNAME: command is not passed -H parameter
      - OBSESS: metric results should be published via obsess command
      - NRPE_SERVICE: metric should be executed via NRPE on service node
      - REQUIREMENT: metric should be generated if req. metric is present on 
        some site 
        (used only for metrics associated with Nagios host)
      - LOCALDEP: metric should be removed if local flag is not on
        (used only for metrics associated with Nagios host)      
    - $parent: name of the metric which runs complex check
      (only if flag PASSIVE is set)
    - $docUrl: URL with metric documentation

Result is 1 if operation is successful, 0 otherwise.

Local metric is added to REALHOSTS only. Local metrics are associated
to metric sets which are associated with all aliases and LB nodes.
Entities in list HOSTS have reference to metrics in REALHOSTS.

=item C<addRemoteMetric>

  $res = $ncg->addRemoteMetric( $host, $metric, $remoteService, $url, $docUrl );

Adds new remote metric to host. If host doesn't exist, method issues warning.

Parameters are:
    - $host: add metric to defined host
    - $metric: metric name
    - $remoteService: name of the remote service which performed
      remote metric
    - $url: URL with detailed output
    - $docUrl: URL with metric documentation

Result is 1 if operation is successful, 0 otherwise.

Remote metric is added to HOSTS only. Remote metrics are associated to reported
names only and not to real host name and LB nodes.

=item C<addLBNode>

  $res = $ncg->addLBNode( $host, $lbnode );

Adds new LB node to host. If host doesn't exist, method issues warning.

Parameters are:
    - $host: add LB node to defined host
    - $lbnode: LB node name

Result is 1 if operation is successful, 0 otherwise.

LB node is added to REALHOSTS only.

=item C<addContact>

  $res = $ncg->addContact( $contact, $enabled );

Adds contact to all entities on site. Variable $enabled defines
if the contact should receive alarms when ENABLE_NOTIFICATIONS
is set to 0 (see SAM-1424).

Site level contacts are kept independently from hosts.

=item C<addHostContact>

  $res = $ncg->addHostContact( $host, $contact, $enabled );

Adds contact to host.

Contact is added to REALHOSTS only because it is reasonable
to expect that the administrator responsible for host is
also responsible for all its aliases.

Variable $enabled defines if the contact should receive alarms 
when ENABLE_NOTIFICATIONS is set to 0 (see SAM-1424).

=item C<addRemoteService>

  $res = $ncg->addRemoteService( $serviceName );

Adds remote services which executed remote metrics which
are imported.

=item C<addUser>

  $res = $ncg->addUser( $dn, $name, $email );

Adds user to a list of users authorized on site.

Parameters are:
    - $dn: certificate DN of user
    - $name: user's full name
    - $email: user's email

Result is 1 if operation is successful, 0 otherwise.

=item C<removeContact>

  $res = $ncg->removeContact( $contact );

Remove contact from all entities on site.

=item C<removeHost>

  $res = $ncg->removeHost( $host );

Removes host from list HOSTS. Removes host from list of aliases
in list REALHOSTS. Entry in REALHOSTS is kept as long as there
is a single alias left.

=item C<removeService>

  $res = $ncg->removeService( $host );

Removes service from host in list HOSTS. Removes service
from list REALHOSTS and from all aliases in list HOSTS.

=item C<removeLBNode>

  $res = $ncg->removeLBNode( $host, $lbnode );

Removes LB node from host in list REALHOSTS.

=item C<siteName>

  print $ncg->siteName;
  $ncg->siteName('egee.srce.hr');

Accessor method for property SITENAME.

=item C<siteROC>

  print $ncg->siteROC;
  $ncg->siteROC('CentralEurope');

Accessor method for property ROC.

=item C<siteLDAP>

  print $ncg->siteLDAP;
  $ncg->siteLDAP('bdii-egee.srce.hr');

Accessor method for property LDAP_ADDRESS.

=item C<hostAttribute>

  print $ncg->hostAttribute( $host, $attr );
  $ncg->hostAttribute( $host, $attr, $value );

Accessor method for attribute $attr on host $host.

Attributes are kept only in list REALHOSTS.

=item C<hostAttributeVO>

  print $ncg->hostAttributeVO( $host, $attr, $vo );
  $ncg->hostAttributeVO( $host, $attr, $vo, $value );

Accessor method for attribute $attr for VO $vo on host
$host.

Attributes for VOs are kept only in list REALHOSTS.

=item C<hostAttributeVOs>

  @attrs = $ncg->hostAttributeVOs( $host, $attr );

Method returns array of attribute values for each VO.

=item C<metric*>

  print $ncg->metric* ( $host, $metric );

Read-only accessors for metric attributes on host $host.

Methods are following: metricType, metricDocUrl, metricProbe
metricNative, metricRemoteService, metricUrl, 
metricConfig, metricAttributes, metricDependencies, metricParent.

See DESCRIPTION, C<addLocalMetric> and C<addRemoteMetric> for
detailed description of metric attributes.

=item C<hostAddress>

  print $ncg->hostAddress ( $host );

Read-only accessor for address of host $host.

=item C<hostAlias>

  print $ncg->hostAlias ( $host );

Read-only accessor for alias of host $host.

=item C<userName>

  print $ncg->userName ( $user );

Read-only accessor for full name of user $user.

=item C<userEmail>

  print $ncg->userEmail ( $user );

Read-only accessor for email of user $user.

=item C<LBNodeAddress>

  print $ncg->LBNodeAddress ( $host, $lbnode );

Read-only accessor for address of LB node $lbnod on host $host.

=item C<getHosts>

  @res = $ncg->getHosts( $host );

Retrieves array of hosts in list HOSTS.

This method is useful for generating configuration for
registered hosts.

=item C<getRealHosts>

  @res = $ncg->getRealHosts( $host );

Retrieves array of hosts in list REALHOSTS.

This method is useful for generating configuration for
load balanced nodes.

=item C<getServices>

  @res = $ncg->getServices( $host );

Retrieves array of services associated with $host from
list HOSTS.

=item C<getRealServices>

  @res = $ncg->getRealServices( $host );

Retrieves array of services associated with $host from
list REALHOSTS.

Since entry in REALHOSTS contains aggregated services,
result is different from result of method C<getServices>.

This method is implemented due to a rare case when real
host name is present in list HOSTS and contains different
set of services from the on in list REALHOSTS. Example:
- real.host.org is registered as service CE
- its alias alias.host.org is registered as service MON

=item C<getRemoteServices>

  @res = $ncg->getRemoteServices( );

Retrieves array of remote services from which remote
metrics will be imported.

=item C<getMetrics>

  @res = $ncg->getMetrics( $host );

Retrieves array of metrics associated with $host from
list HOSTS.

=item C<getLocalMetrics>

  @res = $ncg->getLocalMetrics( $host );

Retrieves array of local metrics associated with $host from
list HOSTS.

=item C<getRemoteMetrics>

  @res = $ncg->getRemoteMetrics( $host );

Retrieves array of remote metrics associated with $host from
list HOSTS.

=item C<getRealMetrics>

  @res = $ncg->getRealMetrics( $host );

Retrieves array of metrics associated with $host from
list REALHOSTS.

See comment for C<getRealServices>

=item C<getLBNodes>

  @res = $ncg->getLBNodes( $host );

Retrieves array of LB nodes associated with host $host.

Array is retrieved from entry in REALHOSTS, but the 
argument $host can be both from HOSTS and REALHOSTS.
In case when alias is used, method will find the
appropriate entry in REALHOSTS by using REAL_HOST
attribute.

=item C<getAliases>

  @res = $ncg->getAliases( $host );

Retrieves array of aliases associated with host $host.

See comment for C<getLBNodes>

=item C<getContacts>

  @res = $ncg->getContacts;

Retrieves array of global contacts associated with
all hosts.

=item C<getHostContacts>

  @res = $ncg->getHostContacts ( $host );

Retrieves array of contacts associated host $host

See comment for C<getLBNodes>

=item C<getUsers>

  @res = $ncg->getUsers;

Retrieves array of users associated with site.

=item C<hasHost>

  $res = $ncg->hasHost ( $host );

Method checks if $host exists in list HOSTS.

=item C<hasRealHost>

  $res = $ncg->hasRealHost ( $host );

Method checks if $host exists in list REALHOSTS.

=item C<hasService>

  $res = $ncg->hasService ( $host, $service );

Method checks if $host in list HOSTS has $service.

=item C<hasRealService>

  $res = $ncg->hasRealService ( $host, $service );

Method checks if $host in list REALHOSTS has $service.

=item C<hasAttribute>

  $res = $ncg->hasAttribute ( $host, $attribute );

Method checks if $host has $attribute defined.

=item C<hasServiceURI>

  $res = $ncg->hasAttribute ( $host, $metricSet );

Method checks if $host has service uri defined
for metric set $metricSet.

=item C<hasContacts>

  $res = $ncg->hasContacts ( $host );

Method checks if $host has contacts defined.

=item C<hasVO>

  $res = $ncg->hasVO ( $host, $vo );

Method checks if there is any service on $host which supports 
$vo.

In case when all services don't have VOs defined, method
returns true. Example is BDII service.

=item C<hasLBNodes>

  $res = $ncg->hasLBNodes ( $host );

Method checks if $host has LB nodes.

=item C<hasMetric>

  $res = $ncg->hasMetric ( $host, $metric );

  $res = $ncg->hasMetric ( $host, $metric, $types );

Method checks if $host has metric $metric.

Argument $types is optional. Argument $types should contain hah reference
with supported metric types. For example, for following value:
  $types = {local=>1, remote=>1}
function will check if the metric exists and if the metric's type is in 
the list of supported types.

=item C<hasMetricNRPEService>

  $res = $ncg->hasMetricNRPEService ( $host );

Method checks if host $host has metric with flag NRPE_SERVICE.
This check is used to see if host needs NRPE config.

=item C<isContactEnabled>

  $res = $ncg->isContactEnabled ( $contact );

Method checks if contact $contact should receive alarms even
if ENABLE_NOTIFICATIONS is switched off (see SAM-1424).

=item C<isHostContactEnabled>

  $res = $ncg->isHostContactEnabled ( $host, $contact );

Method checks if hostcontact $contact should receive alarms even
if ENABLE_NOTIFICATIONS is switched off (see SAM-1424).


=back

=head1 SEE ALSO

  NCG

=cut


1;
