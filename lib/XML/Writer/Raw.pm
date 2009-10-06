package XML::Writer::Raw;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

XML::Writer::Raw - increased recursion functionality for XML::Writer

=head1 SYNOPSIS

    use XML::Writer::Raw;

    # $obj is a Remedy::CMDB::Struct object

    my $string;
    my $writer = XML::Writer::Raw->new ('OUTPUT' => \$string,
        'DATA_INDENT' => 4, 'NEWLINES' => 0, 'DATA_MODE' => 1,
        'UNSAFE' => 1, @args);

    $writer->startTag ($obj->tag_type);

    my %fields = $obj->fields;
    foreach my $field (sort keys %fields) {
        my $data = $obj->$field;
        my $type = $fields{$field};

        if ($type eq '@') {
            foreach my $key (@$data) {
                $writer->write_elem_or_raw ($field, $key);
            }
        } elsif ($type eq '%') {
            foreach my $key (keys %{$data}) {
                $writer->dataElement ($key, $$data{$key});
            }

        } else {
            $writer->write_elem_or_raw ($field, $data);
        }
    }

    $writer->endTag;
    $writer->end;

    print $string;

=head1 DESCRIPTION

This package adds a couple of sub-routines to XML::Writer to best handle the
recursive nature of the B<Remedy::CMDB::Struct> objects.  Essentially, we use
the B<raw ()> function a whole lot more, and with a whole lot less errors.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use XML::Writer;

our @ISA = qw/XML::Writer/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item write_elem_or_raw (FIELD, DATA)

Writes additional fields to the XML document. If I<DATA> is a reference, then
we assume that it is an additional B<Remedy::CMDB::Struct> object, and pull the 
text out with B<xml ()> and run that through B<write_raw_with_format ()>.
Otherwise, we'll just add a dataElement with the field name I<FIELD>.

=cut

sub write_elem_or_raw {
    my ($self, $field, $data) = @_;
    if (ref $data) { $self->write_raw_with_format ($data->xml) }
    else           { $self->dataElement ($field, $data)         }
}

=item write_raw_with_format (TEXT)

Adds I<TEXT> to the XML document in a formatted manner - that is, it adds
appropriate indentation and newlines to make it fit in visually to the whole
document.

Not quite perfect yet; there are still a few too many newlines added in, and
the only local option we're looking at it DATA_INDENT.  But it's a good start.

=cut

sub write_raw_with_format {
    my ($self, $xml) = @_;
    my $indent = " " x $self->getDataIndent;
    $self->raw ("\n");
    foreach my $line (split ("\n", $xml)) {
        if ($line =~ /^\s*$/) { 
            $self->raw ($line);
        } else { 
            my $text = join ('', $indent, $line, "\n");
            $self->raw ($text);
        } 
    }
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<XML::Writer>

=head1 HOMEPAGE

TBD.

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
