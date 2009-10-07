package Remedy::CMDB::Deregister::Response;
our $VERSION = "1.00.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Deregister::Response - XML responses to a registration request

=head1 SYNOPSIS

    use Remedy::CMDB::Register;

=head1 DESCRIPTION

Remedy::CMDB::Deregister::Response is a simple sub-class of the template
B<Remedy::CMDB::Template::Response>.  It is used to create high-level responses
to registration requests.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Exporter;
use Remedy::CMDB::Template::Response;
use Remedy::CMDB::Deregister::ResponseItem;

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

    my @items;
    foreach my $instance ($self->children ('deregisterinstanceResponse')) {
        my $obj = Remedy::CMDB::Deregister::ResponseItem->read ('xml',
                'source' => $instance, 'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        push @items, $obj;
    }

    return;
}

=item tag_type 

I<registerResponse>

=cut

sub tag_type { 'deregisterResponse' }

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
