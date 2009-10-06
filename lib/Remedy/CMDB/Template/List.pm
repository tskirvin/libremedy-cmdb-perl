package Remedy::CMDB::Template::List;
our $VERSION = "0.01";

=head1 NAME

Remedy::CMDB::Template::List - a Remedy::CMDB::Struct object for item lists

=head1 SYNOPSIS

The contents of the package:

    package Remedy::CMDB::Sample::List;

    use Remedy::CMDB::Sample::Record;
    use Remedy::CMDB::Template::List;
    our @ISA = qw/Remedy::CMDB::Template::List;

    sub tag_type   { 'sampleList' }
    sub list_class { 'Remedy::CMDB::Sample::Record' }

=head1 DESCRIPTION

Remedy::CMDB::Template::List supplies a template for parsing lists of items
managed through other templates.  Essentially, we parse XML like this:

    <itemList>
        <item> [...] </item>
        <item> [...] </item>
        <item> [...] </item>
    </itemList>

...into a single Remedy::CMDB::Template::List object containing an array of
B<Remedy::CMDB::Item> objects.

Remedy::CMDB::Template::List is implemented as a B<Remedy::CMDB::Struct>
object.

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

=item list (@)

Contains an array of the contained objects.  

=cut

sub fields { 'list' => '@' }

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
    $self->list ([]);
    return;
}

=item populate_xml (XML)

Confirms the tag type, clears the object, and populates from B<XML::Twig>
object I<XML>.  We look for the B<tag_type ()> from the class in 
B<list_class ()>, and from each item contained within we create a new object.
All of the objects are then stored in B<list ()>.

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    my $type = $self->tag_type;
    my $tag  = $xml->tag;
    return "tag type should be $type, not $tag" unless ($tag eq $type);

    my $list_class = $self->list_class;
    return 'no list class' unless $list_class;
    my $list_type  = $list_class->tag_type;

    $self->clear_object;

    my @items;
    foreach my $item ($xml->children ($list_type)) {
        my $obj = $list_class->read ('xml', 'source' => $item, 
            'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        push @items, $obj;
    }
    $self->list (\@items);
    
    return;
}

=item tag_type ()

Stub.  Defaults to I<invalid item list tag>, which is invalid XML.

=cut

sub tag_type   { "invalid item list tag" }

=back

=cut

##############################################################################
### Additional Functions #####################################################
##############################################################################

=head2 Additional Functions 

=over 4

=item list_class ()

Stub.  Defaults to I<Class::Invalid>, which hopefully doesn't exist.

=cut

sub list_class { 'Class::Invalid' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Struct>

=head1 SEE ALSO

B<Remedy::CMDB::Item::List>, B<Remedy::CMDB::Relationship::List>

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
