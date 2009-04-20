package Remedy::CMDB::Register;
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

use Remedy::CMDB::Register::XML;
use Remedy::CMDB::Register::Remedy;

use Remedy::CMDB::Item;
use Remedy::CMDB::Relationship;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

=cut

sub fields {
    'mdrid'         => '$',
    'items'         => '@',
    'relationships' => '@',
}

=item populate_xml (XML)

Takes an XML::Twig::Elt object I<XML>

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be registerRequest' 
        unless ($xml->tag eq 'registerRequest'); 

    $self->clear_object;
    
    my $mdr = $xml->first_child_text ('mdrId') || '';
    return 'no mdrId' unless $mdr;
    $self->mdrid ($mdr);

    my @items;
    if (my $itemlist = $xml->first_child ('itemList')) {
        foreach my $item ($itemlist->children ('item')) {
            my $obj = Remedy::CMDB::Item->read ('xml', 'source' => $item, 
                'type' => 'object');
            return "no object created" unless $obj;
            return $obj unless ref $obj;
            push @items, $obj;
        }
    }
    $self->items (\@items);

    my @relate;
    if (my $relationshiplist = $xml->first_child ('relationshipList')) {
        foreach my $item ($relationshiplist->children ('relationship')) {
            my $obj = Remedy::CMDB::Relationship->read ('xml', 
                'source' => $item, 'type' => 'object');
            return "no object created" unless $obj;
            return $obj unless ref $obj;
            push @relate, $obj;
        }
    }
    $self->relationships (\@relate);
    
    return;
}

sub populate_remedy { "not yet implemented" }

sub clear_object {
    my ($self) = @_;
    $self->mdrid ('');
    $self->items ([]);
    $self->relationships ([]);
    return;
}

sub text {
    my ($self) = @_;
    my @return;

    push @return, "ID: " . $self->id;
    push @return, '', "Items";
    foreach my $item (@{$self->items}) { 
        foreach ($item->text)     { push @return, '  ' . $_ }
    }
    push @return, '', "Relationships";
    foreach my $relation (@{$self->relationships}) { 
        foreach ($relation->text) { push @return, '  ' . $_ }
    }

    wantarray ? @return : join ("\n", @return, '');
}

sub id {
    my ($self) = @_;
    my $mdrid = $self->mdrid || return;
    # this is wrong but will do for now
    return $mdrid;
}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

sub _getatt { }

sub _getdata {
    warn "_gd: @_\n";
    my ($self, $listname, $objname, $class) = @_;
    return unless my $data = $self->data;
    return unless my $item = $data->first_child ($listname);

    return $item unless $objname;
    my @children = $item->children ($objname);
    return unless scalar @children;

    my @items;
    foreach my $i (@children) {
        $i->print;
        push @items, $class ? $class->new ('type' => 'xml')
                            : $i;
    }
    return @items;
}


##############################################################################
### Final Documentation ######################################################
##############################################################################

1;


