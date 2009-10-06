package Remedy::CMDB::Template::Response::Global::Response;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Global::Response - XML responses to a global error

=head1 SYNOPSIS

    use Remedy::CMDB::Template::Response::Global::Response;

=head1 DESCRIPTION

Remedy::CMDB::Global::Response is a simple sub-class of the template
B<Remedy::CMDB::Template::ResponseItem>.  It is used for global error
responses, where the actual class we should be responding with is not known.

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

I<globalResponse>

=cut

sub tag_type   { "globalResponse" }

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
