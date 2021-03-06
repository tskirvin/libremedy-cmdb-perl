package Remedy::Form::CMDB_Clear;
our $VERSION = "0.51";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB_Clear - delete the contents of BaseElement, etc

=head1 SYNOPSIS

    use Remedy::Form::CMDB_Clear;
    # you know what?  just don't use this class.  it can only end badly
    
=head1 DESCRIPTION

Remedy::Form::CMDB_Clear manages the
I<+CMDB-UATDeleteBaseElementBaseRelationshipRecords> form in Remedy, which is
a specially-designed form that deletes all items in I<BaseElement> and
I<BaseRelationship> when a new item is created (via workflow). 

Remedy::CMDB_Clear is a sub-class of B<Remedy::Form>, and is not separately
registered.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::Form qw/init_struct/;

our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct> Accessors

=over 4

=item text (I<Short Description>)

The text we'll save in the database entry explaining why we ran the clear.

=item mdrId (I<MDR>)

The MDR ID of the items that we want to delete.

=back

=cut

sub field_map { 
    'text'  => 'Short Description',
    'mdrId' => 'MDR ID'
}

##############################################################################
### Remedy::Form Overrides ###################################################
##############################################################################

=head2 B<Remedy::Form Overrides>

=over 4

=item field_map ()

=item table ()

=cut

sub table { '+CMDB-UATDeleteBaseElementBaseRelationshipRecords' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Class::Struct>, B<Remedy::Form>

=head1 SEE ALSO

cmdb-clear(1)

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
