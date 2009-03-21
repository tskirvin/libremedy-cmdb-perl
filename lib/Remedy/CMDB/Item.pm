package Remedy::CMDB::Item;
our $VERSION = "0.01";

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################


##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::XML qw/init_struct/;

our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item new (TYPE, ARGHASH)

=cut

sub read 
sub new {
    my ($self, $type, %args) = @_;
    
    if (!$type) {
        $self->error ('no type set');
        return;
    }

    if      (lc $type eq 'xml') { 
        my $source = $args{'source'};
        return eval { Remedy::CMDB::Relationship::XML->new ($source) };
    } elsif (lc $type eq 'remedy') { 
        # write something here soon
        
    } else {
        $self->error ("invalid type: '$type'");
        return;
    }
}

sub id      { shift->instanceid->id }
sub localid { shift->instanceid->localid }
sub mdrid   { shift->instanceid->mdrid   }

sub fields {
    'instanceid' => 'Remedy::CMDB::Item::InstanceID',
    'records'    => '@',
}

=back

=cut

##############################################################################
### Reporting Functions ######################################################
##############################################################################

=head2 Reporting Functions

=over 4

=item text ()

=cut

sub text {
    my ($self, %args) = @_;
    "populate me";
}

=back

=cut

##############################################################################
### Stubs ####################################################################
##############################################################################

=head2 Stubs

These functions are stubs; the real work is implemented by the sub-functions.

=over 4

=item record

=item source

=item target

=back

=cut

sub record { "Not implemented" }
sub source { "Not implemented" }
sub target { "Not implemented" }

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

=head1 SEE ALSO

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
