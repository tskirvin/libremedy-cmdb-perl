package Remedy::CMDB::RegisterResponse;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

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

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

use Remedy::CMDB::InstanceResponse;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

=cut

sub fields {
    'instance' => '@',
}

=item populate_xml (XML)

Takes an XML::Twig::Elt object I<XML>

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be registerResponse' 
        unless ($xml->tag eq 'registerResponse'); 

    $self->clear_object;

    my @items;
    foreach my $instance ($self->children ('instanceResponse')) {
        my $obj = Remedy::CMDB::InstanceResponse->read ('xml', 
                'source' => $instance, 'type' => 'object');
        return "no object created" unless $obj;
        return $obj unless ref $obj;
        push @items, $obj;
    }
    $self->instance (\@items);

    return;
}

sub clear_object {
    my ($self) = @_;
    $self->instance ([]);
    return;
}

sub add_accepted { shift->add_instance ('accepted', @_) }
sub add_declined { shift->add_instance ('declined', @_) }
sub add_error    { shift->add_instance ('error',    @_) }

sub add_instance {
    my ($self, $type, $item, $text, @args) = @_;
    my $obj = Remedy::CMDB::InstanceResponse->new ();
    my $error = $obj->populate ('item' => $item, 'type' => $type, 
        'string' => $text, @args);
    return $error if $error;
    my $current = $self->instance;
    $self->instance (scalar @$current, $obj);
}

sub tag_type { 'registerResponse' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
