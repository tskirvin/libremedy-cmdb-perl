package Remedy::CMDB::Global;
our $VERSION = "0.01";

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################


##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Global::DataSource;
use Remedy::CMDB::Global::Response;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=cut

sub fields {
    'text' => '$'
}

sub source_data {
    my ($self) = @_;
    my $src = Remedy::CMDB::Global::DataSource->new ('text' => 
        $self->text);
    return $src;
}

sub response { shift; Remedy::CMDB::Global::Response->new (@_) }

sub populate_xml { return 'not yet implemented' }

=back

=cut

##############################################################################
### Reporting Functions ######################################################
##############################################################################

=head2 Reporting Functions

=over 4

=item text ()

=cut

sub tag_type { 'global' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

=head1 SEE ALSO

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
