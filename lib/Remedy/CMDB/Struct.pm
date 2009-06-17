package Remedy::CMDB::Struct;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Struct -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $DEBUG = 0;

our $LOGGER = Remedy::Log->get_logger ();

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use Exporter;
use XML::Twig;
use XML::Writer;
use Remedy::Log;

our @EXPORT    = qw//;
our @EXPORT_OK = qw/init_struct/;
our @ISA       = qw/Exporter/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item init_struct (CLASS, ARGHASH)

=cut

sub init_struct {
    my ($class, %extra) = @_;
    $LOGGER->all ("initializing structure for '$class'");
    our $new = $class . "::Struct";

    my %fields = $class->fields;
    struct $new => {
        'type'      => '$',
        'error'     => '$',
        'data'      => '$',
        %fields
    };

    return (__PACKAGE__, $new);
}

## intentionally left blank
sub fields { () }

=item read (SOURCE, ARGHASH)

=cut

sub read {
    my ($self, $source, %opts) = @_;
    $self = $self->new unless (ref $self);

    my $obj;
    if    (lc $source eq 'xml')    { $obj = $self->read_xml    (%opts)  }
    elsif (lc $source eq 'remedy') { $obj = $self->read_remedy (%opts)  }
    else                           { return "invalid source: '$source'" }

    if (! ref $obj) {
        my $error = $obj || "unknown error";
        die "$error\n";
    }
    return $obj;
}

=item read_xml (ARGHASH)

=over 4

=item source

=item type

=back

=cut

sub read_xml {
    my ($self, %opts) = @_;
    my $class = ref $self;

    my $type   = $opts{'type'}   || return "no valid type";
    my $source = $opts{'source'} || return "no valid source";

    my ($xml, $data);
    if      (lc $type eq 'stream') {
        my $xml = XML::Twig->new ();
        return "could not parse: $@" unless $xml->safe_parse ($source);
        $data = $xml->root;
    } elsif (lc $type eq 'file') {
        my $xml = XML::Twig->new ();
        return "could not parse: $@" unless $xml->safe_parsefile ($source);
        $data = $xml->root;
    } elsif (lc $type eq 'object') {
        $data = $source;
    } else {
        return "invalid type: '$type'";
    }

    if (my $error = $self->populate_xml ($data)) {
        $LOGGER->error ("$class: couldn't populate from XML: $error");
        return;
    }

    $self->type ('xml');
    $self->data ($data);
    $LOGGER->info ('created type ' . $data->tag);

    return $self;
}

sub read_remedy { }

sub populate_remedy { "not configured" }
sub populate_xml    { "not configured" }

sub tag_type { 'not configured' }

## subroutines we'll want later, if just to override
sub text    {
    my ($self, @args) = @_;
    my @return;

    push @return, $self->tag_type;

    my %fields = $self->fields;
    foreach my $field (sort keys %fields) {
        my $data = $self->$field;
        my $type = $fields{$field};
        # push @return, "  $field";

        if ($type eq '@') {
            push @return, "  $field";
            foreach my $key (@$data) {
                if (ref $key) {
                    foreach ($key->text) { push @return, "    $_" }
                } else {
                    push @return, "    $_";
                }
            }

        } elsif ($type eq '%') {
            push @return, "  $field";
            foreach my $key (keys %{$data}) {
                push @return, "    $key: $$data{$key}";
            }

        } else {
            if (ref $data) {
                push @return, "  $field";
                foreach ($data->text) { push @return, "    $_" }
            } else {
                push @return, "  $field: $_";
            }
        }
    }
    return wantarray ? @return : join ("\n", @return, '');
}

sub xml     {
    my ($self, @args) = @_;

    my $string;
    my $writer = XML::Writer->new ('OUTPUT' => \$string, 'DATA_INDENT' => 4,
        'NEWLINES' => 0, 'DATA_MODE' => 1, 'UNSAFE' => 1, @args);

    $writer->startTag ($self->tag_type);

    my %fields = $self->fields;
    foreach my $field (sort keys %fields) {
        my $data = $self->$field;
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

    return $string;
}

sub db_save {}
sub db_load {}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

##############################################################################
### XML::Writer Subroutines ##################################################
##############################################################################

package XML::Writer;

=head2 XML::Writer Subroutines 

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

1;
