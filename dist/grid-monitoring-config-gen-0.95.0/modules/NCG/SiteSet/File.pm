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

package NCG::SiteSet::File;

use NCG::SiteSet;
use NCG::SiteDB;
use strict;
use vars qw(@ISA);

@ISA=("NCG::SiteSet");

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self =  $class->SUPER::new(@_);

    if ( defined $self->{DB_FILE} ) {
        if (! -f $self->{DB_FILE})
        {
            $self->error("Can't find static file!");
            undef $self;
            return 0;
        }
        $self->{DB_FILES}->{$self->{DB_FILE}} = 1;
    }

    if ( defined $self->{DB_DIRECTORY} ) {
        if (! -d $self->{DB_DIRECTORY})
        {
            $self->error("Can't find static directory!");
            undef $self;
            return 0;
        }
        my $filelist = [];
        $self->_addRecurseDirs($filelist, $self->{DB_DIRECTORY});
        foreach my $file (@$filelist) {
            $self->{DB_FILES}->{$file} = 1;
        }
    }

    if ( !defined $self->{DB_DIRECTORY} && ! defined $self->{DB_FILE} ) {
        $self->error("File of directory name must be defined!");
        undef $self;
        return 0;
    }

    $self;
}

sub getData
{
    my $self = shift;
    my $line;
    my $fileHndl;

    foreach my $file (keys %{$self->{DB_FILES}}) {
        if (!open ($fileHndl, $file)) {
            $self->error("Cannot open static file!");
            return 0;
        }
        while ($line = <$fileHndl>) {
            next if ($line =~ /^\s*#.*$/);
            if ($line =~ /^\s*(\S+?)!(\S+?)(!(\S+?))?(!(\S+?))?\s*$/) {
                my $action = $1;
                if ($action eq "SITE" || $action eq "ADD_SITE") {
                    $self->{SITES}->{$2} = NCG::SiteDB->new ({SITENAME=>$2});
                } elsif ($action eq "SITE_BDII" || $action eq "ADD_SITE_BDII") {
                    $self->{SITES}->{$2} = NCG::SiteDB->new ({SITENAME=>$2, LDAP_ADDRESS=>$4});
                } elsif ($action eq "ADD_ROC_SITE") {
                    $self->{SITES}->{$4} = NCG::SiteDB->new ({ROC=>$2, SITENAME=>$4});
                } elsif ($action eq "ADD_ROC_SITE_BDII") {
                    $self->{SITES}->{$4} = NCG::SiteDB->new ({ROC=>$2, SITENAME=>$4, LDAP_ADDRESS=>$6});
                } elsif ($action eq "REMOVE_SITE") {
                    delete $self->{SITES}->{$2} if (exists $self->{SITES}->{$2});
                } else {
                    $self->debug("Unknown command found: $1");
                }
            }
        }
        close ($fileHndl);
    }
    1;
}

=head1 NAME

NCG::SiteSet::File

=head1 DESCRIPTION

The NCG::SiteSet::File module extends NCG::SiteSet module. Module
extracts list of sites from file with list of tuples:
  # this is a comment
  # adds site
  ADD_SITE!sitename
  # adds site with Site BDII
  ADD_SITE_BDII!sitename!site_bdii_address
  # adds site to a ROC/NGI
  ADD_ROC_SITE!rocname!sitename
  # adds site to a ROC/NGI with Site BDII
  ADD_ROC_SITE_BDII!rocname!sitename!site_bdii_address
  # removes site
  REMOVE_SITE!sitename


=head1 SYNOPSIS

  use NCG::SiteSet::File;

  my $siteInfo = NCG::SiteSet::File->new( { DB_FILE => '/path/to/tuplelist' } );

  $siteInfo->getData();

=cut

=head1 METHODS

=over

=item C<new>

  $siteInfo = NCG::SiteSet::File->new( $attr );

Creates new NCG::SiteSet::File instance. Argument $attr is hash
reference that can contains following elements:
  DB_FILE - location of file with list of tuples (no default)
  DB_DIRECTORY - directory with files with list of tuples (no default)

=back

=head1 SEE ALSO

NCG::Site

=cut

1;
