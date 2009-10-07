package Remedy::CMDB::Query;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Query - CMDB query service

=head1 SYNOPSIS

    use Remedy::CMDB::Query;
    
=head1 DESCRIPTION

None of this is actually complete; this is just a stub.

Remedy::CMDB::Query is a sub-class of B<Remedy::CMDB::Struct>, and inherits
many functions from there.

=cut

##############################################################################
### Configuration ############################################################
##############################################################################
# Nothing local.

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Query::Response;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

Currently empty.

=over 4

=back

=cut

sub fields { }

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.

=over 4

=item fields 

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    return;
}

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return;
}

=item tag_type ()

=cut

sub tag_type { 'queryRequest' }

=item text ()

=cut

sub text {
    my ($self) = @_;
    return;
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Query::Response>, B<Remedy::CMDB::Struct>

=head1 SEE ALSO

Remedy::CMDB(8), Remedy::CMDB::Register(8)

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
