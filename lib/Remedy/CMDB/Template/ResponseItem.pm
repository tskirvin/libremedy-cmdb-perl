package Remedy::CMDB::Template::ResponseItem;
our $VERSION = "0.50.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Template::ResponseItem - template for responses to activities

=head1 SYNOPSIS

The contents of the package:

    package Remedy::CMDB::Sample::ResponseItem;

    use Remedy::CMDB::Template::ResponseItem;
    our @ISA = qw/Remedy::CMDB::Template::ResponseItem/;

    sub tag_type { 'sampleResponse' }

=head1 DESCRIPTION

Remedy::CMDB::Template::ResponseItem offers a template to generate XML 
responses storing the results of an action against the CMDB - that is, the
result of a registration (and, eventually, a query).  This generally means
either a successful response that looks like this (using the
'registerInstanceResponse' type):

    <registerInstanceResponse>
        <instanceId>
            <localId>000011112222</localId>
            <mdrId>http://networking.stanford.edu</mdrId>
        </instanceId>
        <accepted>
            <notes>no changes</notes>
            <alternateInstanceId>
                <localId>1254855204.000011112222@http://networking.stanford.edu</localId>
                <mdrId>MDR.IMPORT.NETWORKING</mdrId>
            </alternateInstanceId>
        </accepted>
    </registerInstanceResponse>

...or a failure like this:

    <registerInstanceResponse>
        <instanceId>
            <localId>173.64.10.0-23</localId>
            <mdrId>http://networking.stanford.edu</mdrId>
        </instanceId>
        <declined>
            <reason>failed to translate MDR info: [...]</reason>
        </declined>
    </registerInstanceResponse>

Or, if there's a global failure, it will look like this:

    <globalResponse>
        <dataSource>GLOBAL</dataSource>
        <declined>
            <reason>bad input XML</reason>
        </declined>
    </globalResponse>

Remedy::CMDB::Template::ResponseItem is implemented as a B<Remedy::CMDB::Struct>
object.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Item::AlternateInstanceID;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item alternateId (@)

An array of alternate instance IDs, where the data was actually stored.  Used 
with type I<accepted>.

=item source_data ($)

Either a reference to the item that we're generating this response from, or the
string 'GLOBAL'.

=item string ($)

A string explaining the reason for failure or note about the success.

=item type ($)

The type of response.  We recognize I<accepted>, I<declined>, and I<error>.

=cut

sub fields {
    'alternateId' => '@',
    'source_data' => '$',
    'string'      => '$',
    'type'        => '$',
}

=back

=cut

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->alternateId ([]);
    $self->source_data (undef);
    $self->string      (undef);
    return;
}

=item populate_xml (XML)

Parses the XML.  Not well tested, to be honest.

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be '
        unless ($xml->tag eq 'instanceResponse');

    $self->clear_object;

    my @items;
    if (my $declined = $xml->first_child ('declined')) {
        my @reasons;
        foreach ($declined->children ('reason')) {
            push @reasons, $_->string;
        }
        $self->reason (@reasons);
    }

    if (my $accept = $xml->first_child ('accepted')) {
        my @alternate;
        foreach my $item ($accept->children ('alternateInstanceId')) {
            my $obj = Remedy::CMDB::Item::AlternateInstanceID->read ('xml',
                'source' => $item, 'type' => 'object');
            return 'no object created' unless $obj;
            return $obj unless ref $obj;
            my $id = $obj;
            push @alternate, $id;
        }
        $self->alternate (@alternate)
    }

    return 'cannot be both declined and accepted'
        if ($self->reason && $self->alternateId);
    return 'must be either declined or accepted'
        unless ($self->reason || $self->alternateId);

    {
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
    }

    return;
}

=item tag_type ()

Stub.  Defaults to I<invalid responseItem tag>, which is invalid XML.

=cut

sub tag_type { 'invalid responseItem tag' }

=item xml ()

Returns an XML representation of the object, using B<XML::Writer::Raw>.  We use
this instead of the default because this information is simply more dynamic and
difficult to represent than usual.

=cut

sub xml {
    my ($self, @args) = @_;

    my $string;
    my $writer = XML::Writer::Raw->new ('OUTPUT' => \$string, 
        'DATA_INDENT' => 4, 'NEWLINES' => 0, 'DATA_MODE' => 1, 
        'UNSAFE' => 1, @args);

    $writer->startTag ($self->tag_type);
    
    my $src_data = $self->source_data || '';
    if (ref $src_data) { 
        $writer->write_raw_with_format ($src_data->xml);
    } else {
        $writer->write_elem_or_raw ('dataSource', $src_data);
    }

    my $alternate = $self->alternateId;

    my $type = lc $self->type;
    if ($type eq 'accepted') { 
        $writer->startTag ('accepted');
        $writer->dataElement ('notes', $self->string);
        $writer->setDataIndent ($writer->getDataIndent + 4);    ## HACK
        foreach (@$alternate) {
            $writer->write_elem_or_raw ('alternateInstanceId', $_);
        }
        $writer->setDataIndent ($writer->getDataIndent - 4);    ## HACK
        $writer->endTag;
    } elsif ($type eq 'declined') {
        $writer->startTag ('declined');
        $writer->dataElement ('reason', $self->string);
        $writer->endTag;
    } elsif ($type eq 'error') { 
        $writer->startTag ('declined');
        $writer->dataElement ('reason', "ERROR: " . $self->string);
        $writer->endTag;
    } else {
        $writer->startTag ('declined');
        $writer->dataElement ('reason', "ERROR: invalid response type ($type)");
        $writer->endTag;
    }

    $writer->endTag;
    $writer->end;
    
    return $string;
}

=back

=cut

##############################################################################
### Additional Functions #####################################################
##############################################################################

=head2 Additional Functions 

=over 4

=item populate (ARGHASH)

=cut

sub populate {
    my ($self, %args) = @_;
    return 'no item' unless my $item = $args{'item'};

    my $data = ref $item ? $item->source_data : 'GLOBAL';
    $self->source_data ($data);

    my $type = $args{'type'} || 'default';
    if    ($type eq 'accepted') { return $self->populate_accepted (%args) }
    elsif ($type eq 'declined') { return $self->populate_declined (%args) }
    elsif ($type eq 'error')    { return $self->populate_error    (%args) }
    else                        { return "invalid type: $type" }
}

=item populate_accepted (ARGHASH)

=over 2

=item obj I<Remedy::CMDB::Item>

=item string I<STRING>

=cut

sub populate_accepted {
    my ($self, %args) = @_;
    $self->type ('accepted');
    if (my $obj = $args{'obj'}) {
        my $alternate = Remedy::CMDB::Item::AlternateInstanceID->new;
        $alternate->mdrId   ($obj->get ('DatasetId'));
        $alternate->localId ($obj->get ('InstanceId'));
        $self->alternateId (0, $alternate);
    }
    $self->string ($args{'string'});
    return;
}

=item populate_declined (ARGHASH)

=cut

sub populate_declined {
    my ($self, %args) = @_; 
    $self->type ('declined');
    $self->string ($args{'string'});
    return;
}

=item populate_error (ARGHASH)

=cut

sub populate_error { 
    my ($self, %args) = @_;
    $self->type ('declined');
    $self->string ($args{'string'});
    return;
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Item::AlternateInstanceID>, B<Remedy::CMDB::Struct>

=head1 SEE ALSO

Remedy::CMDB::Template::Response(3)

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
