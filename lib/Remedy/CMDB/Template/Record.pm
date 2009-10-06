package Remedy::CMDB::Template::Record;
our $VERSION = "0.01";

=head1 NAME

Remedy::CMDB::Template::Record - template for storing CMDB information

=head1 SYNOPSIS

The contents of the package:

    package Remedy::CMDB::Sample::Record;

    use Remedy::CMDB::Template::ID;
    our @ISA = qw/Remedy::CMDB::Template::ID/;

    sub tag_type { 'sampleRecord' }

=head1 DESCRIPTION

Remedy::CMDB::Template::Record offers a consistent template for managing
information about a single record - specifically, the datatype, a number of
data fields with values, and a number of metadata fields with values.  For
example, say the XML looks like this (using 'record' as an example):

    <record>
        <computerSystem>
            <AssetClass>Hardware</AssetClass>
            <HostName>pchg-web1.stanford.edu</HostName>
            <Model>PowerEdge 1750</Model>
            <Name>pchg-web1.stanford.edu</Name>
            <PrimaryCapability>Server</PrimaryCapability>
            <SerialNumber>6ZYMF51</SerialNumber>
            <ShortDescription>pchg-web1.stanford.edu</ShortDescription>
            <firmware_version></firmware_version>
        </computerSystem>
        <recordMetadata>
            <recordClass>Production</recordClass>
            <recordId />
        </recordMetadata>
    </record>

In this case, the datatype is 'computerSystem'; there is data for the
'AssetClass', 'HostName', 'Model', etc fields; and there is metadata for
'recordClass' and 'recordId'.

Remedy::CMDB::Template::Record is implemented as a B<Class::Struct> object with
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

=item data (%)

Contains a set of key/value pairs containing all primary data about the object.

=item datatype ($)

Stores the 'class' of the data.

=item meta (%)

Contains a set of key/value pairs containing metadata about the object.  

=cut

sub fields {
    'data'     => '%',
    'datatype' => '$',
    'meta'     => '%',
}

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.  Sub-classes of the template will probably want to override those
functions labelled 'stub'.

=over 4

=item fields ()

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->meta ({});
    $self->data ({});
    $self->datatype (undef);
    return;
}

=item populate_xml (XML)

Confirms the tag type, clears the object, and populates from B<XML::Twig>
object I<XML>.  We parse the information from the 
<mdrId> and <localId>; if either is missing, then we return with an error.

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be record' unless (lc $xml->tag eq 'record'); 
    
    $self->clear_object;

    my $count;
    foreach my $child ($xml->children) {
        my $tag = $child->tag;
        if ($tag eq 'recordMetadata') { 
            foreach my $subchild ($child->children) {
                my $subtag = $subchild->tag;
                my $subval = $subchild->child_text;
                $self->meta ($subtag, $subval);
            }
        } else {
            return 'too many items in record' if $count++;
            $self->datatype ($tag);
            foreach my $subchild ($child->children) { 
                my $subtag = $subchild->tag;
                my $subval = $subchild->child_text;
                $self->data ($subtag, $subval);
            }
        }
    }
    return 'no items in count' unless $count;

    return;
}

=item tag_type ()

Stub.  Defaults to I<invalid record tag>, which is invalid XML.

=cut

sub tag_type { "invalid record tag" } 

=item text ()

Returns a formatted array or string containing (in order) the data type, the
real data, and the metadata.

=cut

sub text {
    my ($self, %args) = @_;
    my @return;

    push @return, "Data Type: " . $self->datatype;
    if (my $data = $self->data) { 
        push @return, "Data";
        foreach (keys %{$data}) {
            push @return, "  $_: $$data{$_}";
        }
    }

    my $meta = $self->meta;
    if (scalar keys %{$meta}) {
        push @return, "Metadata";
        foreach (keys %{$meta}) { 
            push @return, "  $_: $$meta{$_}";
        }
    } 
        
    return wantarray ? @return : join ("\n", @return, '');
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
