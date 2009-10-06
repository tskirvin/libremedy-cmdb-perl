package Remedy::CMDB::Item::Response;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Item::Response - XML responses to an item registration

=head1 SYNOPSIS

    use Remedy::CMDB::Item::Response;

=head1 DESCRIPTION

Remedy::CMDB::Item::Response is a simple sub-class of the template
B<Remedy::CMDB::Template::ResponseItem>.  It is used for item registrations.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Template::ResponseItem;

our @ISA = qw/Remedy::CMDB::Template::ResponseItem/;

##############################################################################
### Remedy::CMDB::Template::ResponseItem Overrides ###########################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::ResponseItem> Overrides

=over 4

=item tag_type ()

I<registerInstanceResponse>

=cut

sub tag_type   { "registerInstanceResponse" }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Template::ResponseItem>

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
