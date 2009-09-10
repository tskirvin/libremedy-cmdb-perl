package Remedy::CMDB::Template::Response;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Template::Response - template for XML responses

=head1 SYNOPSIS

    use Remedy::CMDB::Template::Response;

=head1 DESCRIPTION

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Global;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=cut

##############################################################################
### Base Operations ##########################################################
##############################################################################

=head2 Base Operations

=over 4

=item fields ()

[...]

=over 4

=item instance (@)

=back

=cut

sub fields {
    'instance' => '@',
}

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->instance ([]);
    return;
}

=item populate_xml (XML)

Takes an XML::Twig::Elt object I<XML> [...]

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    my $type = $self->tag_type;
    return "tag type should be $type" unless ($xml->tag eq $type);

    $self->clear_object;

    my @items;
    foreach my $instance ($self->children ('instanceResponse')) {
        my $obj = Remedy::CMDB::Item::Response->read ('xml', 
                'source' => $instance, 'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        push @items, $obj;
    }
    foreach my $instance ($self->children ('relationshipResponse')) {
        my $obj = Remedy::CMDB::Relationship::Response->read ('xml', 
                'source' => $instance, 'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        push @items, $obj;
    }
    foreach my $instance ($self->children ('deregisterResponse')) {
        my $obj = Remedy::CMDB::DeregisterResponse->read ('xml', 
                'source' => $instance, 'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        push @items, $obj;
    }
    $self->instance (\@items);

    return;
}

=back

=cut

##############################################################################
### Functions To Override ####################################################
##############################################################################

=head2 Functions To Override

=over 4

=item tag_type ()

Returns 'response'.  Should be over

=cut

sub tag_type { 'invalid tag' }

=back

=cut

##############################################################################
### Item Functionality #######################################################
##############################################################################

=head2 Item Functionality

=over 4

=item add_instance (TYPE, ITEM, TEXT)

=cut

sub add_instance {
    my ($self, $type, $item, $text, @args) = @_;
    my $obj = ref $item ? $item->response
                        : Remedy::CMDB::Global->new->response;
     
    my $error = $obj->populate ('item' => $item, 'type' => $type, 
        'string' => $text, @args);
    return $error if $error;
    my $current = $self->instance;
    $self->instance (scalar @$current, $obj);
}

=item add_accepted (ITEM, TEXT)

=item add_declined (ITEM, TEXT)

=item add_error (ITEM, TEXT)

=cut

sub add_accepted { shift->add_instance ('accepted', @_) }
sub add_declined { shift->add_instance ('declined', @_) }
sub add_error    { shift->add_instance ('error',    @_) }

=back

=cut

##############################################################################
### Exported Functions #######################################################
##############################################################################

=head2 Exported Functions

=over 4

=item exit_error ()

=cut

sub exit_error {
    my ($self, $text, %args) = @_;
    my $response = $self->new ();
    $response->add_error ('global', $text);
    $response->exit_response ('FATAL' => 1, %args);
}

=item exit_response (ARGHASH)

=cut

sub exit_response {
    my ($self, %args) = @_;
    print scalar $self->xml;
    exit defined $args{'FATAL'} ? 1 : 0;
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
