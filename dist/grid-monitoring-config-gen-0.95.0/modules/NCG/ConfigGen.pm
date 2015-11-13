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

package NCG::ConfigGen;

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

NCG::ConfigGen

=head1 DESCRIPTION

The NCG::ConfigGen module is abstract class for generating
configuration.
Each module extending NCG::ConfigGen must implement method
getConfig.

=head1 SYNOPSIS

  use NCG::ConfigGen;
  $ncg = NCG::ConfigGen->new( $attr );
  $ncg->getData();
  
=cut

=head1 METHODS

=over

=item C<new>

  $dbh = NCG::ConfigGen->new( $attr );

Creates new NCG::ConfigGen instance.

=item C<getData>

  $ncg->getData ();

Abstract method for generating configuration.

=back

=head1 SEE ALSO

  NCG

=cut

1;
