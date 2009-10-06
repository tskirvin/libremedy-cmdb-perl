package Remedy::CMDB::Template::ID;
our $VERSION = "0.50.00";

=head1 NAME

Remedy::CMDB::Template::ID - template for parsing scoped MDRs for CMDB

=head1 SYNOPSIS

The contents of the package:

    package Remedy::CMDB::Sample::ID;

    use Remedy::CMDB::Template::ID;
    our @ISA = qw/Remedy::CMDB::Template::ID/;

    sub tag_type { 'sampleId' }

=head1 DESCRIPTION

Remedy::CMDB::Template::ID offers a consistent template for managing what is
referred to in the CMDB documentation as a 'cmdbf:MdrScopedIdType' object
- that is, a combination of a localId and an mdrId in XML.  The XML looks
something like this using an 'instanceId' as an example:

    <instanceId>
        <mdrId>https://windows.stanford.edu/CMDBf</mdrId>
        <localId>test-host</localId>
    </instanceId>

Remedy::CMDB::Template::ID is implemented as a B<Class::Struct> object with
some additional functions.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item localId ($)

The "name" of the service, e.g. 'cmdb-test.stanford.edu'.

=item mdrId ($)

The "public" version of the dataset name, e.g. 'http://puppet.stanford.edu'.
'mdr' stands for 'Master Data Record'.

=cut

sub fields {
    'localId' => '$',
    'mdrId'   => '$',
}

=back

=cut

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.  Sub-classes of the template will probably want to override those
functions labelled 'stub'.

=over 4

=item fields 

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->mdrId   (undef);
    $self->localId (undef);
    return;
}

=item populate_xml (XML)

Confirms the tag type, clears the object, and populates from B<XML::Twig>
object I<XML>.  We're looking for the first items of each of the two fields
<mdrId> and <localId>; if either is missing, then we return with an error.

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

=item tag_type ()

Stub.  Defaults to I<invalid id tag>, which is invalid XML.

=cut

sub tag_type { "invalid id tag" }

=item text ()

Returns the value of B<id ()> (see below).

=cut

sub text { return shift->id }

=back

=cut

##############################################################################
### Additional Functions #####################################################
##############################################################################

=head2 Additional Functions 

=over 4

=item id ()

Creates a "canonical" ID by joining the localId and the mdrId with an '@'.

=cut

sub id {
    my ($self) = @_;
    return join ('@', $self->localId, $self->mdrId);
}

=item match_mdr (ID)

Returns an error if the B<mdrId ()> of item I<ID> does not match the B<mdrId
()> of the current object.  Returns undef if they do match.

=cut

sub match_mdr {
    my ($self, $id) = @_;
    return 'mdr does not match' unless $id->mdrId eq $self->mdrId;
    return;
}

=item populate (mdrId, localId)

Populates the item with I<mdrId> and I<localId>.

=cut

sub populate {
    my ($self, $mdrId, $localId) = @_;
    $self->mdrId   ($mdrId);
    $self->localId ($localId);
    return;
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Struct>

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
