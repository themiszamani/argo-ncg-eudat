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

package NCG::SiteContacts;

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

NCG::SiteContacts

=head1 DESCRIPTION

The NCG::SiteContacts module is abstract class for extracting information
about authorized personnel on site. Each module extending NCG::SiteContacts
must implement method getData.

This module is primarily used by ncg.pl program for generating Nagios
configuration for grid sites. However, it can be used by any other
tools for extracting basic site/service information.

=head1 SYNOPSIS

  use NCG::SiteContacts;
  my $ncg = NCG::SiteContacts->new($options);
  $res = $ncg->getData();

=cut

=head1 METHODS

=over

=item C<new>

  $dbh = NCG::SiteContacts->new( $attr );

Creates new NCG::SiteContacts instance.

=item C<getData>

  $res = $dbh->getData();

Abstract method for gathering site information.

=back

=head1 SEE ALSO

=cut

1;
