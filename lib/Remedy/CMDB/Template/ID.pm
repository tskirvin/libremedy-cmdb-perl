package Remedy::CMDB::Template::ID;
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

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

All items 

=over 4

=item mdrid ($)

=item localid ($)

=back

=cut

sub fields {
    'mdrid'   => '$',
    'localid' => '$',
}

sub populate {
    my ($self, $mdrid, $localid) = @_;
    $self->mdrid   ($mdrid);
    $self->localid ($localid);
    return;
}

sub match_mdr {
    my ($self, $id) = @_;
    return 'mdr does not match' unless $id->mdrid eq $self->mdrid;
    return;
}

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    my $type = $self->tag_type;
    my $tag  = $xml->tag;
    return "tag type should be $type, not $tag" unless ($tag eq $type);

    $self->clear_object;

    my $mdr = $xml->first_child_text ('mdrId') || '';
    return 'no mdrId' unless $mdr;
    $self->mdrid ($mdr);

    my $local = $xml->first_child_text ('localId') || '';
    return 'no localId' unless $local;
    $self->localid ($local);

    return;
}

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->mdrid   (undef);
    $self->localid (undef);
    return;
}

=back

=cut

##############################################################################
### Reporting Functions ######################################################
##############################################################################

=head2 Reporting Functions

=over 4

=item id ()

Creates a "canonical" ID by joining the localid and the mdrid.

=cut

sub id {
    my ($self) = @_;
    return join ('@', $self->localid, $self->mdrid);
}

=item text ()

=cut

sub text { return shift->id }

=back

=cut

##############################################################################
### Stubs ####################################################################
##############################################################################

=head2 Stubs

These functions are stubs; the real work is implemented by the sub-functions.

=over 4

=item tag_type ()

=cut

sub tag_type { "not populated" }

=back

=cut

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


1;
