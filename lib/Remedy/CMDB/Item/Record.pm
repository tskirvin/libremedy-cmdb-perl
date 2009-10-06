package Remedy::CMDB::Item::Record;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Item::Record - record information in an Item

=head1 SYNOPSIS

    use Remedy::CMDB::Item::Record;

=head1 DESCRIPTION

Remedy::CMDB::Item::Recordis a simple sub-class of the template
B<Remedy::CMDB::Template::Record>.  It is used to keep track of the the actual
record information of a B<Remedy::CMDB::Item>.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Remedy::CMDB::Template::Record;

our @ISA = qw/Remedy::CMDB::Template::Record/;

##############################################################################
### Remedy::CMDB::Template::Record Overrides #################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::Record> Overrides

=over 4

=item tag_type ()

I<record>

=cut

sub tag_type { "record" }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Template::Record>

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
