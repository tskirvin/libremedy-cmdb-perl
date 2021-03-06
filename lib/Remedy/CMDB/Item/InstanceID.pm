package Remedy::CMDB::Item::InstanceID;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Item::InstanceID - info about  instance IDs

=head1 SYNOPSIS

    use Remedy::CMDB::Item::InstanceID;

=head1 DESCRIPTION

Remedy::CMDB::Item::InstanceID is a simple sub-class of the template
B<Remedy::CMDB::Template::ID>.  It is used to keep track of the information in
an InstanceID field.

=cut


##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Remedy::CMDB::Template::ID;

our @ISA = qw/Remedy::CMDB::Template::ID/;

##############################################################################
### Remedy::CMDB::Template::ID Overrides #####################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::ID> Overrides

=over 4

=item tag_type ()

I<InstanceId>

=cut

sub tag_type { "instanceId" }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Template::ID>

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
