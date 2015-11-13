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

package NCG::RemoteMetrics;

use strict;
use NCG;
use vars qw(@ISA);

@ISA=("NCG");

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);
    $self;
}

=head1 NAME

NCG::RemoteMetrics

=head1 DESCRIPTION

The NCG::RemoteMetrics module is abstract class for extracting
information about remote metrics which are available for each host.
Each module extending NCG::RemoteMetrics must implement method getMetrics.

=head1 SYNOPSIS

  use NCG::RemoteMetrics;
  $ncg = NCG::SiteInfo->new( $attr );
  $ncg->getData();

=cut

=head1 METHODS

=over

=item C<new>

  $ncg = NCG::RemoteMetrics->new( $attr );

Creates new NCG::RemoteMetrics instance.

=item C<getData>

  $ncg->getData ();

Abstract method for gathering metric information.

=back

=head1 SEE ALSO

=cut


1;
