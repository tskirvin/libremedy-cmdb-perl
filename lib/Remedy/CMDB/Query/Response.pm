package Remedy::CMDB::Query::Response;
our $VERSION = "0.01.02";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Query::Reponse - XML response to a query request

=head1 SYNOPSIS

    use Remedy::CMDB::Query;

=head1 DESCRIPTION

Remedy::CMDB::Register::Response is a simple sub-class of the template
B<Remedy::CMDB::Template::Response>.  It is used to create high-level responses
to registration requests.

Not yet in use.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Template::Response;

our @ISA = qw/Remedy::CMDB::Template::Response/;

##############################################################################
### Remedy::CMDB::Template::Response Overrides ###############################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::Response> Overrides

=over 4

=item populate_xml (XML)

Not yet written.

=cut

sub populate_xml { 'not yet written' }

=item tag_type

I<queryResponse>

=cut

sub tag_type { 'queryResponse' }

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
