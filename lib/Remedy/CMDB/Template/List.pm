package Remedy::CMDB::Template::List;
our $VERSION = "0.01";

=head1 NAME

Remedy::CMDB::Template::List - a Remedy::CMDB::Struct object for item lists

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

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

All items 

=over 4

=item list (@)

=back

=cut

sub fields { 'list' => '@' }

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    my $type = $self->tag_type;
    my $tag  = $xml->tag;
    return "tag type should be $type, not $tag" unless ($tag eq $type);

    my $list_class = $self->list_class;
    return 'no list class' unless $list_class;
    my $list_type  = $list_class->tag_type;

    $self->clear_object;

    my @items;
    foreach my $item ($xml->children ($list_type)) {
        my $obj = $list_class->read ('xml', 'source' => $item, 
            'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        push @items, $obj;
    }
    $self->list (\@items);
    
    return;
}

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->list ([]);
    return;
}

=back

=cut

##############################################################################
### Reporting Functions ######################################################
##############################################################################

=head2 Reporting Functions

=over 4

=item text ()

=cut

sub text { 
    my ($self) = @_;
    ## FIXME: actually write something here
}

=back

=cut

##############################################################################
### Stubs ####################################################################
##############################################################################

=head2 Stubs

These functions are stubs; the real work is implemented by the sub-functions.

=over 4

=item tag_type ()

=cut

sub list_class { 'not populated' }
sub list_type  { 'not populated' }
sub tag_type   { "not populated" }

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
