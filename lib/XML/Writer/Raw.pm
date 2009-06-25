package XML::Writer::Raw;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

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

use XML::Writer;

our @ISA = qw/XML::Writer/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

This package adds a couple of sub-routines to XML::Writer to best handle the
recursive nature of the 

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
            my $text = join ('', $indent, $indent, $line, "\n");
            $self->raw ($text);
        } 
    }
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
