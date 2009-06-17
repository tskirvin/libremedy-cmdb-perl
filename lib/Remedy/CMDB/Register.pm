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

use Remedy::CMDB::ItemList;
use Remedy::CMDB::Relationship;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

=cut

sub fields {
    'mdrId'         => '$',
    'itemlist'      => 'Remedy::CMDB::ItemList',
    'relationships' => '@',
}

=item populate_xml (XML)

Takes an XML::Twig::Elt object I<XML>

=cut

sub populate_xml {
    warn "PX: @_\n";
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'invalid tag type: ' . $xml->tag
        unless ($xml->tag eq $self->tag_type); 

    $self->clear_object;
    
    my $mdr = $xml->first_child_text ('mdrId') || '';
    return 'no mdrId' unless $mdr;
    $self->mdrId ($mdr);

    my @items;
    if (my $itemlist = $xml->first_child ('itemList')) {
        my $obj = Remedy::CMDB::ItemList->read ('xml', 'source' => $itemlist,
            'type' => 'object');
        return 'no object created' unless $obj;
        return $obj unless ref $obj;
        $self->itemlist ($obj);
    }

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
    $self->mdrId ('');
    $self->itemlist ();
    $self->relationships ([]);
    return;
}

sub text {
    my ($self) = @_;
    my @return;

    push @return, "ID: " . $self->id;
    push @return, '', "Items";
    foreach my $item (@{$self->itemlist->list}) { 
        foreach ($item->text)     { push @return, "  $_" }
    }
    push @return, '', "Relationships";
    foreach my $relation (@{$self->relationships}) { 
        foreach ($relation->text) { push @return, "  $_" }
    }

    wantarray ? @return : join ("\n", @return, '');
}

sub items {
    my ($self) = @_;
    return unless my $itemlist = $self->itemlist;
    return unless my $list = $itemlist->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

sub relationships {
    my ($self) = @_;
    
    return [];
}

sub id {
    my ($self) = @_;
    my $mdrId = $self->mdrId || return;
    # this is wrong but will do for now
    return $mdrId;
}

sub tag_type { 'registerRequest' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;


