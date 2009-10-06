package Remedy::CMDB::Item::List;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Item::List - lists of <item> tags

=head1 SYNOPSIS

    use Remedy::CMDB::Item::Target;

=head1 DESCRIPTION

Remedy::CMDB::Item::Target is a simple sub-class of the template
B<Remedy::CMDB::Template::List>.  It is used to keep track of a list of
B<Remedy::CMDB::Item> objects.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Remedy::CMDB::Template::List;
use Remedy::CMDB::Item;

our @ISA = qw/Remedy::CMDB::Template::List/;

##############################################################################
### Remedy::CMDB::Template::List Overrides ###################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::List> Overrides

=over 4

=item list_class

I<Remedy::CMDB::Item>

=cut

sub list_class { 'Remedy::CMDB::Item' }

=item tag_type ()

I<itemList>

=cut

sub tag_type { "itemList" }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Template::List>

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
