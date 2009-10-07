package Remedy::CMDB::Deregister::ResponseItem;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Deregister::ResponseItem - XML responses to an item deregistration

=head1 SYNOPSIS

    use Remedy::CMDB::Deregister::ResponseItem;

=head1 DESCRIPTION

Remedy::CMDB::Deregister::Response is a simple sub-class of the template
B<Remedy::CMDB::Template::ResponseItem>.  It is used for item deregistrations.

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

=head2 B<Remedy::CMDB::Template::Response> Overrides

=over 4

=item tag_type ()

I<deregisterInstanceResponse>

=cut

sub tag_type   { "deregisterInstanceResponse" }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Template::Response>

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
