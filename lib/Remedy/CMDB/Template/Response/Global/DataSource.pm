package Remedy::CMDB::Template::Response::Global::DataSource;
our $VERSION = "1.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Template::Response::Global::DataSource - XML responses to an item registration

=head1 SYNOPSIS

    use Remedy::CMDB::Template::Response::Global::DataSource;

=head1 DESCRIPTION

Remedy::CMDB::Template::Response::Global::DataSource is a simple sub-class of
the template B<Remedy::CMDB::Struct>.  It is used to store a small piece of
text for B<Remedy::CMDB::Global>'s error messages.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item text ($)

The text of the error message.

=back

=cut

sub fields { 'text'  => '$' }

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.

=over 4

=item fields ()

=item tag_type ()

I<dataSource>

=cut

sub tag_type { "dataSource" }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Struct>

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
