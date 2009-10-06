package Remedy::CMDB::Relationship::Source;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Relationship::Source - ID information about relationship source

=head1 SYNOPSIS

    use Remedy::CMDB::Relationship::Source;

=head1 DESCRIPTION

Remedy::CMDB::Relationship::Source is a simple sub-class of the template
B<Remedy::CMDB::Template::ID>.  It is used to keep track of the source of a
relationship.

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

I<source>

=cut

sub tag_type { "source" }

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
