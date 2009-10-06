package Remedy::CMDB::Struct;
our $VERSION = "0.50";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Struct - Class::Struct for CMDB data structures

=head1 SYNOPSIS

The contents of the package:

    package Remedy::CMDB::Sample;

    use Remedy::CMDB::Struct qw/init_struct/;
    our @ISA = init_struct (__PACKAGE__);

    sub fields {
        'field1'    => '$',
        'field2'    => '@',
        'field3'    => '%'
    }

    sub populate_xml {
        my ($self, $xml) = @_;
        return 'no xml' unless ($xml && ref $xml);
        my $type = $self->tag_type;
        return "tag type should be $type" unless ($xml->tag eq $type);

        $self->clear_object;
        # actually parse the XML and pull out data

        return;
    }

    sub tag_type { 'sample' }

In the script:

    use Remedy::CMDB::Sample;

    my $sample = { Remedy::CMDB::Sample->read ('xml', 'type' => 'stream',
        'source' => \*STDIN) };
    die "could not read XML: $@\n" unless $sample;

    print scalar $sample->text;

=head1 DESCRIPTION

Remedy::CMDB::Struct offers a a basic structure for B<Remedy::CMDB> data
structures, which is based around the idea of recursively creating data
structures for all of the data stored in an XML document.  Essentially, each
class knows information about itself and its children, stored in a
B<populate_xml ()> function;

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $LOGGER = Remedy::Log->get_logger ();

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use Exporter;
use Remedy::Log;
use XML::Twig;
use XML::Writer::Raw;

our @EXPORT    = qw//;
our @EXPORT_OK = qw/init_struct/;
our @ISA       = qw/Exporter/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item init_struct (CLASS, ARGHASH)

Registers a new B<Remedy::CMDB::*> sub-class, and initializes its interface
with a number of B<Class::Struct> accessors.  I<CLASS> is the name of the
class.

The new sub-class is based around a B<Class::Struct> object, with the following
accessors:

=over 4

=item data ($)

Stores an B<XML::Twig::Elt> object that contains the data that we parsed

=item error ($)

=item type ($)

=item (per-object B<Class::Struct> accessors) (various)

Adds accessors of the name/types listed in the B<fields ()> function.

=back

=cut

sub init_struct {
    my ($class, %extra) = @_;
    $LOGGER->all ("initializing structure for '$class'");
    our $new = $class . "::Struct";
    my %fields = $class->fields;
    struct $new => {'data'  => '$', 'error' => '$', 'type'  => '$', %fields};
    return (__PACKAGE__, $new);
}

=back

=cut

##############################################################################
### Functions To Override ####################################################
##############################################################################

=head2 Functions To Override

The following functions may have sensible defaults, but it is expected that
sub-classes will override them where possible.

=over 4

=item fields ()

Defaults as empty.  You probably won't get much out of the sub-classes unless
you populate this.

=cut

sub fields { () }

=item clear_object ()

Empties the object.  This is generally run by B<populate_xml ()>, but otherwise
isn't vital.  Defaults as empty function, since there's nothing in B<fields
()>.

=cut

sub clear_object { undef }

=item populate_xml (XML)

Populates the item from a fragment of XML, as offered from the B<XML::Twig>
object I<XML>.

You really want to populate this function, but it's difficult to explain
exactly what it should look like.  There is no default, but the sample offered
in SYNOPSIS should give you a good start.  The following is an example of how
we populate the glossed-over part, from B<Remedy::CMDB::Item>:

    my $id;
    foreach my $item ($xml->children ('instanceId')) {
        return 'too many instanceIds' if $id;
        my $obj = Remedy::CMDB::Item::InstanceID->read ('xml',
            'source' => $item, 'type' => 'object');
        return 'no object created' unless $obj;
        return $obj unless ref $obj;
        $id = $obj;
    }
    $self->instanceId ($id);

    return "no instanceId" unless $self->instanceId;

    my $record;
    foreach my $item ($xml->children ('record')) {
        return 'too many objects' if $record;
        my $obj = Remedy::CMDB::Item::Record->read ('xml',
            'source' => $item, 'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        $record = $obj;
    }
    $self->record ($record);

The important detail here: we are invoking B<read ()> on the sections of XML on
a regular basis, and that B<read ()> will invoke B<populate_xml ()>.  This will
recurse until all relevant objects are populated.

Returns undef on success, or an error string with an error.

=cut

sub populate_xml { "populate_xml () not configured" }

=item tag_type ()

Defines the name of the XML tag.  The default is I<tag type not configured>,
which will hopefully fail in every useful context; you definitely want to
override this function as well.

=cut

sub tag_type { 'tag type not configured' }

=item text ()

Creates a textual representation of the object.  The default actually isn't too
bad; it will list the tag type, and data from all of the fields listed in
B<fields ()>.  Depending on context, returns either an array of text lines
suitable for printing to the screen, or a single string merged with newlines.

If you really want to print this, you'll probably want to use the pragma:

    print scalar $obj->text;

=cut

sub text    {
    my ($self, @args) = @_;
    my @return;

    push @return, $self->tag_type;

    my %fields = $self->fields;
    foreach my $field (sort keys %fields) {
        my $data = $self->$field;
        my $type = $fields{$field};

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

=item xml (ARGS)

Creates a (hopefully human-readable) chunk of XML containing all knowledge
about this object.  This uses B<XML::Writer::Raw>, passing in extra arguments
from I<ARGS>.  Returns a string containing the full XML.

=cut

sub xml {
    my ($self, @args) = @_;

    my $string;
    my $writer = XML::Writer::Raw->new ('OUTPUT' => \$string,
        'DATA_INDENT' => 4, 'NEWLINES' => 0, 'DATA_MODE' => 1,
        'UNSAFE' => 1, @args);

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

=back

=cut

##############################################################################
### Regular Methods# #########################################################
##############################################################################

=head2 Regular Methods

These methods provide the interesting functionality of the Remedy::CMDB::Struct
object.

=over 4

=item read (SOURCE, ARGHASH)

Offers a high-level interface to populate an item based on an arbitrary source.
Based on I<SOURCE>, we invoke a sub-function:

=over 4

=item xml => B<read_xml (ARGHASH)>

=back

If we can't read for some reason (including an invalid source), die with an
error message.  Otherwise, return the populated object.

=cut

sub read {
    my ($self, $source, %opts) = @_;
    $self = $self->new unless (ref $self);

    my $obj;
    if    (lc $source eq 'xml') { $obj = $self->read_xml (%opts)    }
    else                        { die "invalid source: '$source'\n" }

    if (! ref $obj) {
        my $error = $obj || "unknown error";
        die "$error\n";
    }
    return $obj;
}

=item read_xml (ARGHASH)

Populates the item from a piece of XML.  This is generally parsed

I<ARGHASH> is a hash of key/value pairs.  We recognize the following:

=over 4

=item source I<SRC>

Where is the data actually coming from.  See below to understand what exactly
this means.  Required.

=item type I<TYPE>

Where the data is coming from.  This is one of the following values:

=over 2

=item stream

I<SRC> should be an open filehandle.

=item file

I<SRC> should be a filename.

=item object

I<SRC> should be an B<XML::Twig::Elt> object.  Used for recursion.
this is used for recursion).

=back

Required.

=back

Once we have the parsed data, then we will parse it with B<populate_xml ()>.
See above to explain how this works.

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
        $LOGGER->logdie ("$class: couldn't populate from XML: $error\n");
        return;
    }

    $self->type ('xml');
    $self->data ($data);
    $LOGGER->info ('created type ' . $data->tag);

    return $self;
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::Log>, B<XML::Twig>, B<XML::Writer::Raw>

=head1 HOMEPAGE

TBD.

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
