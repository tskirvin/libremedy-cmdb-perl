package Remedy::CMDB::Response;
our $VERSION = "1.00.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Response - XML responses to all requests

=head1 SYNOPSIS

    use Remedy::CMDB::Response;

=head1 DESCRIPTION

Remedy::CMDB::Response is a simple sub-class of the template
B<Remedy::CMDB::Template::Response>.  It is used to create simple but 
high-level responses requests where we don't yet know what kind of errors to
look at - that is, we just want to return a parseable error message, but we
don't know if we're registering or querying the service yet.

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

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    my $type = $self->tag_type;
    return "tag type should be $type" unless ($xml->tag eq $type);

    $self->clear_object;

    return;
}

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
