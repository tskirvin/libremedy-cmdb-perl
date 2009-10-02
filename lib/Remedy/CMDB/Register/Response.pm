package Remedy::CMDB::Register::Response;
our $VERSION = "1.00.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Register::Response - XML responses to a registration request

=head1 SYNOPSIS

    use Remedy::CMDB::Register;

=head1 DESCRIPTION

Remedy::CMDB::Register::response is a simple sub-class of
B<Remedy::CMDB::Template::Response>.  

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Exporter;
use Remedy::CMDB::Template::Response;

our @ISA = qw/Remedy::CMDB::Template::Response/;
our @EXPORT_OK = qw/exit_error exit_response/;

##############################################################################
### Remedy::CMDB::Template::Response Overrides ###############################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::Response> Overrides

=over 4

=item tag_type 

I<registerResponse>

=back

=cut

sub tag_type { 'registerResponse' }

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
