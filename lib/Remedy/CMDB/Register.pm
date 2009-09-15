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

use Lingua::EN::Inflect qw/inflect/;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

use Remedy::CMDB::Item::List;
use Remedy::CMDB::Relationship::List;
use Remedy::CMDB::Register::Response;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

=cut

sub fields {
    'mdrId'             => '$',
    'itemList'          => 'Remedy::CMDB::Item::List',
    'relationshipList'  => 'Remedy::CMDB::Relationship::List',
    'deregisterList'    => 'Remedy::CMDB::Deregister::List',
}

=item populate_xml (XML)

Takes an XML::Twig::Elt object I<XML>

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'invalid tag type: ' . $xml->tag
        unless ($xml->tag eq $self->tag_type); 

    $self->clear_object;

    my $mdr = $xml->first_child_text ('mdrId') || '';
    return 'no mdrId' unless $mdr;
    $self->mdrId ($mdr);

    if (my $itemlist = $xml->first_child ('itemList')) {
        my $obj = Remedy::CMDB::Item::List->read ('xml', 'source' => $itemlist,
            'type' => 'object');
        return 'could not parse itemList' unless $obj;
        return $obj unless ref $obj;
        $self->itemList ($obj);
    }

    if (my $relationshiplist = $xml->first_child ('relationshipList')) {
        my $obj = Remedy::CMDB::Relationship::List->read ('xml', 
            'source' => $relationshiplist, 'type' => 'object');
        return 'could not parse relationshipList' unless $obj;
        return $obj unless ref $obj;
        $self->relationshipList ($obj);
    }
    
    return;
}

## need to add error checking to this, but it mostly works...
sub register_all {
    my ($self, $cmdb, %args) = @_;
    my $logger = $cmdb->logger_or_die;

    my $dataset = $args{'dataset'};
    my $mdr     = $args{'mdr'};

    my $response = Remedy::CMDB::Register::Response->new ();

    $logger->debug ('registering all items');
    $self->do_register_all ($cmdb, [$self->items], 'type' => 'item', 
        'response' => $response, 'dataset' => $dataset, 'mdr' => $mdr);

    $logger->debug ('registering all relationships');   
    $self->do_register_all ($cmdb, [$self->relationships], 
        'type' => 'relationships', 'response' => $response, 
        'dataset' => $dataset, 'mdr' => $mdr);

    $logger->debug ('registering all deregister requests');   
    $self->do_register_all ($cmdb, [$self->deregisters], 
        'type' => 'deregister', 'response' => $response, 
        'dataset' => $dataset, 'mdr' => $mdr);
        
    return $response;
}

sub do_register_all {
    my ($self, $cmdb, $item_aref, %args) = @_;
    my $response = $args{'response'};
    my ($count, $error_count) = (0, 0);
    foreach my $item (@$item_aref) { 
        $count++;
        my $error = $item->register ($cmdb, 'response' => $args{'response'},
            'dataset' => $args{'dataset'}, 'mdr_parent' => $args{'mdr'});
        if ($error) { 
            $response->add_declined ($item, $error) if $error;
            $error_count++;
        }
    }
    $cmdb->logger_or_die->info (sprintf ("%s out of %s", 
        inflect ("NUM($error_count) registration PL_N(error)"),
        inflect ("NUM($count) PL_N($args{'type'})")));
}

sub populate_remedy { "not yet implemented" }

sub clear_object {
    my ($self) = @_;
    $self->mdrId ('');
    $self->itemList ();
    $self->relationshipList ();
    return;
}

sub text {
    my ($self) = @_;
    my @return;

    push @return, '', "Items";
    foreach my $item (@{$self->itemList->list}) { 
        foreach ($item->text)     { push @return, "  $_" }
    }
    push @return, '', "Relationships";
    foreach my $relation (@{$self->relationshipList}) { 
        foreach ($relation->text) { push @return, "  $_" }
    }

    wantarray ? @return : join ("\n", @return, '');
}

sub items {
    my ($self) = @_;
    return unless my $itemlist = $self->itemList;
    return unless my $list = $itemlist->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

sub relationships {
    my ($self) = @_;
    return unless my $relationshiplist = $self->relationshipList;
    return unless my $list = $relationshiplist->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

sub deregisters { 
    return; 
}

sub tag_type { 'registerRequest' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
