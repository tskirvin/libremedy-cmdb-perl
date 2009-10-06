package Remedy::CMDB::Template::Response;
our $VERSION = "0.50.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Template::Response - template for XML responses

=head1 SYNOPSIS

The contents of the package:

    package Remedy::CMDB::Sample::Response;

    use Remedy::CMDB::Template::Response;
    use Exporter;

    our @ISA       = qw/Remedy::CMDB::Template::Response/;
    our @EXPORT_OK = qw/exit_error exit_response/;

    sub tag_type { 'sampleResponse' }

In the script:

    use Remedy::CMDB::Sample::Response;
    my $response = Remedy::CMDB::Sample::Response->new;
    $response->add_error ('global', "generic and fake error");
    return scalar $response->xml;

=head1 DESCRIPTION

Remedy::CMDB::Template::Response offers a template for XML responses to CMDB
requests.  The general format of this response looks like this (using a
'registerResponse' as an example):

    <registerResponse>
        <registerInstanceResponse>
            <instanceId>cmdbf:MdrScopedIdType</instanceId>
            <accepted>
                <alternateInstanceId>
                    cmdbf:MdrScopedIdType
                </alternateInstanceId> *
                <notes>
                    list-of-changes
                </notes> ?
            </accepted> ?
            <declined>
                <reason>xs:string</reason> *
            </declined> ?
        <registerInstanceResponse> *
    </registerResponse>

Remedy::CMDB::Template::Response is implemented as a B<Remedy::CMDB::Struct>
object.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Template::Response::Global;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item instance (@)

Contains an array of objects, each of which is the response to a single action
- that is, a B<Remedy::CMDB::Template::Response::Global::Response> or
B<Remedy::CMDB::Item::Response> object.  More generally, they should all be 
B<Remedy::CMDB::Template::ResponseItem> objects.  

=cut

sub fields {
    'instance' => '@',
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
    $self->instance ([]);
    return;
}

=item populate_xml (XML)

Stub.  Should confirm the tag type, clear the object, and populate it from the
B<XML::Twig> object I<XML>.  As we don't know what we're looking for in the
template, we'll only do the first two items.

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    my $type = $self->tag_type;
    return "tag type should be $type" unless ($xml->tag eq $type);

    $self->clear_object;

    return;
}

=item tag_type ()

Stub.  Defaults to I<invalid response tag>, which is invalid XML.

=cut

sub tag_type { 'invalid response tag' }

=back

=cut

##############################################################################
### Error Management #########################################################
##############################################################################

=head2 Error Management 

=over 4

=item add_instance (TYPE, ITEM, TEXT)

Adds a new item to the B<instance ()> array.

I<ITEM> is the source of the response - e.g., a B<Remedy::CMDB::Item> object -
or, if we are just offered a string, we'll create a new B<Remedy::CMDB::Template::Response::Global>
object instead.  The actual response is then created using the B<response ()>
function on that object, and then populated with I<TYPE>, I<ITEM>, and I<TEXT>
using B<populate ()>.

Returns an error message on failure, or undef on success.

=cut

sub add_instance {
    my ($self, $type, $item, $text, @args) = @_;
    my $obj = ref $item ? $item->response
                        : Remedy::CMDB::Template::Response::Global->new->response;

    my $error = $obj->populate ('item' => $item, 'type' => $type,
        'string' => $text, @args);
    return $error if $error;
    my $current = $self->instance;
    $self->instance (scalar @$current, $obj);
    return;
}

=item add_accepted (ITEM, TEXT)

=item add_declined (ITEM, TEXT)

=item add_error (ITEM, TEXT)

Invokes B<add_instance ()> with I<accepted>, I<declined>, or I<error> as
I<TYPE>, respectively.  

=cut

sub add_accepted { shift->add_instance ('accepted', @_) }
sub add_declined { shift->add_instance ('declined', @_) }
sub add_error    { shift->add_instance ('error',    @_) }

=back

=cut

##############################################################################
### Exported Functions #######################################################
##############################################################################

=head2 Exported Functions

These functions are exported (using B<Exporter)> if specifically requested.
They can be used as helpful failure scripts in invoking scripts.

=over 4

=item exit_error (TEXT, ARGHASH)

Exit the script with an error.  We do this cleanly, by creating a new object,
add a global error message (based on I<TEXT>), and 
invoking B<exit_response ('FATAL' => 1, ARGHASH)>).

=cut

sub exit_error {
    my ($self, $text, %args) = @_;
    my $response = $self->new ();
    $response->add_error ('global', $text);
    $response->exit_response ('FATAL' => 1, %args);
}

=item exit_response (ARGHASH)

Prints the current XML to STDOUT, and exits.  Takes the following from the
argument hash I<ARGHASH>:

=over 4

=item FATAL I<INT>

If set, then we will exit with error code 1 (instead of 0).

=back

=cut

sub exit_response {
    my ($self, %args) = @_;
    print scalar $self->xml;
    exit defined $args{'FATAL'} ? 1 : 0;
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 NOTES

The original specification for the response came from the 'registration
response' section of the CMDB techspecs page:

    https://ikiwiki.stanford.edu/projects/cmdb/techspecs/

A few changes have been made.  The two most prominent: the specification was
somewhat enhanced to handle responses in other areas (especially 'global'
responses), and the 'notes' field was added to explain why a change was
accepted.

=head1 REQUIREMENTS

B<Remedy::CMDB::Template::Response::Global>, B<Remedy::CMDB::Struct>

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
