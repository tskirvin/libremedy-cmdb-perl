package Remedy::CMDB::Server::Response;
our $VERSION = "0.50";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Server::Response - create XML responses for CMDB server

=head1 SYNOPSIS

    use Remedy::CMDB::Server::Response;

    my $response = Remedy::CMDB::Server::Response->new;
    $response->add_error ('global', "generic and fake error");
    return scalar $response->xml;

=head1 DESCRIPTION

Remedy::CMDB::Server::Response is a sub-class of the template
B<Remedy::CMDB::Template::Response>.  It is used by B<Remedy::CMDB::Server> to
generate generic responses when there are high-level errors.  In general, that
class will return errors with the classes I<queryResponse> or
I<registerResponse> as appropriate, but if we never got far enough to know
which one of those to generate, we use this class instead.

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
### Overrides ################################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Remedy::CMDB::Template::Response> Overrides

=over 4

=item tag_type

I<cmdbResponse>

=cut

sub tag_type { 'cmdbResponse' }

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
