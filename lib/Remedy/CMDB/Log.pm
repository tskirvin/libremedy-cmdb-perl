package Remedy::CMDB::Log;
our $VERSION = "0.50";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Log - logging for the Remedy CMDB

=head1 SYNOPSIS

    use Remedy::CMDB::Log;

    our $LOGGER = Remedy::CMDB::Log->get_logger ();
    $LOGGER->fatal ('I am a fatal error message');

=head1 DESCRIPTION

Remedy::CMDB::Log provides stderr and file logging for the Remedy::CMDB.  It is
inherited from of B<Remedy::Log>, and is mostly documented there.

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $NAME = "cmdb";

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::Log;
our @ISA = qw/Remedy::Log/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item get_logger ()

Returns the current logger object, or B<Log::Log4perl::get_logger ('cmdb')> if
invoked outside of an item.

=cut

sub get_logger {
    my ($self) = @_;
    return $self->logger if (ref $self && $self->logger);
    return Log::Log4perl::get_logger ($NAME);
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::Log>

=head1 SEE ALSO

Log::Log4perl(8)

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
