package Remedy::CMDB::Deregister::RelationshipList;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Deregister::RelationshipList - lists of <relationship> tags

=head1 SYNOPSIS

    use Remedy::CMDB::Deregister::RelationshipList;

=head1 DESCRIPTION

Remedy::CMDB::Deregister::RelationshipList is a simple sub-class of the
template B<Remedy::CMDB::Template::List>.  It is used to keep track of a list
of B<Remedy::CMDB::Deregister::Relationship> objects.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Remedy::CMDB::Template::List;
use Remedy::CMDB::Deregister::Relationship;

our @ISA = qw/Remedy::CMDB::Template::List/;

##############################################################################
### Remedy::CMDB::Template::List Overrides ###################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::List> Overrides

=over 4

=item list_class

I<Remedy::CMDB::Deregister::Item>

=cut

sub list_class { 'Remedy::CMDB::Deregister::Relationship' }

=item tag_type ()

I<itemIDList>

=cut

sub tag_type { "relationshipIdList" }

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
