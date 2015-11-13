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

package NCG::ConfigPublish::ConfigCache;

use strict;
use NCG::ConfigPublish;
use NCG::ConfigConverter;
use Messaging::Message;
use Messaging::Message::Queue;

use vars qw(@ISA);

@ISA=("NCG::ConfigPublish");

sub new
{
    my $proto  = shift;
    my $args = shift;
    my $argsCopy = {%$args};
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new($args);

    $self->{CONVERTER} = new NCG::ConfigConverter($argsCopy);
    $self->{SEND_TO_MSG} = 1
        unless (defined $self->{SEND_TO_MSG});

    if ($self->{BACKUP_INSTANCE}) {
        $self->{SEND_TO_MSG} = 0;
    }

    $self;
}


sub getData {
    my $self = shift;
    my $changeEUID;
    my $tuple = $self->{CONVERTER}->getJSONConfig();
    my $nagios_host = $self->{CONVERTER}->{NAGIOS_SERVER} or
        $self->error("NAGIOS_SERVER not set!") and return;
    my $role = $self->{CONVERTER}->{NAGIOS_ROLE} or
        $self->error("NAGIOS_ROLE not set!") and return;
    my $site = $self->{CONVERTER}->{SITE_NAME} or
        $self->error("SITE_NAME not set!") and return;
    my $roc = $self->{CONVERTER}->{ROC};

    my $metadata = {
        sitename    => $site,
        role        => $role,
        nagios_host => $nagios_host
    };
    $metadata->{ROC} = $roc if ($roc);

    if ($> == 0) {
        my $nagios_uid;
        ($nagios_uid = getpwnam("nagios")) or
            $self->error("Cannot get info for user nagios!") and return;
        $> = $nagios_uid;
        $changeEUID = 1;
    }

    my $msg = Messaging::Message->new(header => $metadata);
    my $mq;
    $site =~ s/\./_/g;
    $msg->body($tuple);
    $msg->header_field("destination", "/topic/grid.config.metricOutput.EGEE.$role.$site");

    if ($self->{SEND_TO_MSG}) {
        $mq = Messaging::Message::Queue->new(type => 'DQS', path => "/var/spool/msg-nagios-bridge/outgoing-messages");
        $mq->add_message($msg);
    }

    if ($changeEUID) {
        $> = 0;
    }

    1;
}

=head1 NAME

NCG::ConfigPublish::ConfigCache

=head1 DESCRIPTION

The NCG::ConfigPublish::ConfigCache module extends NCG::ConfigPublish module.
Module generates configuration and publish it to ConfigCache.

=head1 SYNOPSIS

  use NCG::ConfigPublish::ConfigCache;

  my $ncg = NCG::ConfigPublish::ConfigCache->new( { SITEDB=> $sitedb } );

  $ncg->getData();

=cut

=head1 METHODS

=over

=item C<new>

  $ncg = NCG::ConfigPublish::ConfigCache->new( $options );

Creates new NCG::ConfigPublish::ConfigCache instance. Argument $options is hash
reference that can contain following elements:
  BACKUP_INSTANCE - if set SEND_TO_MSG will be set to 0. This variable is 
                    used for setting up backup SAM instance (SAM-1127)
  (default: unset)

  NAGIOS_ROLE - defines if this is site-level or multisite-level instance.
              - valid values: site, ROC
  (default: site)

  SEND_TO_MSG - if set to 0 configuration will not be stored to directory 
                queue for sending to message bus. Configuration will only 
                be stored to directory queue for local metric store.
  (default: 1)

  VO - which VO credentials should be used for local probes. It is possible
  to define multiple VOs with comma separated list:
    VO = vo1,vo2,vo3,...
  (default: dteam)

=back

=head1 SEE ALSO

NCG::ConfigPublish
NCG::ConfigConverter
GridMon::ConfigCache
Messaging::Message
Messaging::Message::Queue

=cut

1;
