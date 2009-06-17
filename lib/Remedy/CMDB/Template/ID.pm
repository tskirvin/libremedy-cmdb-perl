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

=item mdrId ($)

=item localId ($)

=back

=cut

sub fields {
    'mdrId'   => '$',
    'localId' => '$',
}

sub populate {
    my ($self, $mdrId, $localId) = @_;
    $self->mdrId   ($mdrId);
    $self->localId ($localId);
    return;
}

sub match_mdr {
    my ($self, $id) = @_;
    return 'mdr does not match' unless $id->mdrId eq $self->mdrId;
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
    $self->mdrId ($mdr);

    my $local = $xml->first_child_text ('localId') || '';
    return 'no localId' unless $local;
    $self->localId ($local);

    return;
}

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->mdrId   (undef);
    $self->localId (undef);
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

Creates a "canonical" ID by joining the localId and the mdrId.

=cut

sub id {
    my ($self) = @_;
    return join ('@', $self->localId, $self->mdrId);
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
