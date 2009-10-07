package Remedy::CMDB::Deregister;
our $VERSION = "0.50.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Deregister - CMDB de-registration service

=head1 SYNOPSIS

    use Remedy::CMDB::Deregister;
    
    # $cmdb is an existing CMDB object - see Remedy::CMDB
    my $register = eval { Remedy::CMDB::Deregister->read ('xml', 
        'type' => 'stream', 'source' => \*STDIN) };
    die "could not load registration XML: $@\n" unless $register;

    my $itemcount         = $register->items;
    my $relationshipcount = $register->relationships;

    my $mdr_parent = $register->mdrId;
    die "no mdr parent in XML\n" unless $mdr_parent;

    my $dataset = $cmdb->config->mdr_to_dataset ($mdr_parent);
    die "no associated dataset for $mdr_parent\n" unless $dataset;
    
    my $response = $register->register_all ($cmdb, 'dataset' => $dataset,
        'mdr' => $mdr_parent);
    die "no response from registration object: $@\n" unless $response;

    $response->exit_response;

=head1 DESCRIPTION

Remedy::CMDB::Deregister de-registers CIs from the CMDB.  It parses a piece
of deregistration XML into three pieces of information: a list of items to be
deregistered, a list of relationships to be deregistered, and a parent MDR
in which all of this work is to be done.  From there, we offer functions to
actually perform the work.

Remedy::CMDB::Deregister is a sub-class of B<Remedy::CMDB::Struct>, and inherits
many functions from there.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Lingua::EN::Inflect qw/inflect/;
use Remedy::CMDB::Deregister::ItemList;
use Remedy::CMDB::Deregister::RelationshipList;
use Remedy::CMDB::Deregister::Response;
use Remedy::CMDB::Relationship::List;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item itemList (B<Remedy::CMDB::Deregister::ItemList>)

A list of items to be deregistered.

=item relationshipList (B<Remedy::CMDB::Deregister::RelationshipList>)

A list of relationships to be deregistered.

=item mdrId (I<MDR>)

The data source that this registration information came from.

=back

=cut

sub fields {
    'itemList'         => 'Remedy::CMDB::Deregister::ItemList',
    'relationshipList' => 'Remedy::CMDB::Deregister::RelationshipList',
    'mdrId'            => '$',
}

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.

=over 4

=item fields 

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->mdrId ('');
    $self->itemList ();
    return;
}

=item populate_xml (XML)

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

    if (my $itemlist = $xml->first_child ('itemIdList')) {
        my $obj = Remedy::CMDB::Deregister::ItemList->read ('xml', 
            'source' => $itemlist, 'type' => 'object');
        return 'could not parse itemIdList' unless $obj;
        return $obj unless ref $obj;
        $self->itemList ($obj);
    }

    if (my $rellist = $xml->first_child ('relationshipIdList')) {
        my $obj = Remedy::CMDB::Deregister::RelationshipList->read ('xml', 
            'source' => $rellist, 'type' => 'object');
        return 'could not parse relationshipIdList' unless $obj;
        return $obj unless ref $obj;
        $self->relationshipList ($obj);
    }

    return;
}

=item tag_type ()

I<deregisterRequest>

=cut

sub tag_type { 'deregisterRequest' }

=back

=cut

##############################################################################
### Additional Functions #####################################################
##############################################################################

=head2 Additional Functions 

=over 4


=item items ()

Returns an array of B<Remedy::CMDB::Deregister::Item> objects, pulled from
B<itemList ()>.

=cut

sub items {
    my ($self) = @_;
    return unless my $itemlist = $self->itemList;
    return unless my $list = $itemlist->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

=item relationships ()

Returns an array of B<Remedy::CMDB::Deregister::Relationship> objects, pulled
from B<relationshipList ()>.

=cut

sub relationships {
    my ($self) = @_;
    return unless my $itemlist = $self->relationshipList;
    return unless my $list = $itemlist->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

=item register_all (CMDB, ARGHASH)

Deregisters all of the items stored in this object.

I<CMDB> is a connected B<Remedy::CMDB> object.  I<ARGHASH> is a hash of
arguments, which

=over 4

=item dataset I<DATASET>

Dataset that the data will be stored in within the CMDB.  Required.

=item mdr I<MDR>

Data source of the registered information.  Required.

=back

Returns a B<Remedy::CMDB::Deregister::Response> object populated with
information about what happened during this registration.

=cut

sub register_all {
    my ($self, $cmdb, %args) = @_;
    my $logger = $cmdb->logger_or_die;

    my $dataset = $args{'dataset'};
    my $mdr     = $args{'mdr'};

    my $response = Remedy::CMDB::Deregister::Response->new ();

    $logger->debug ('de-registering all items');
    $self->do_register_all ($cmdb, [$self->items], 'type' => 'item', 
        'response' => $response, 'dataset' => $dataset, 'mdr' => $mdr);

    $logger->debug ('de-registering all relationships');
    $self->do_register_all ($cmdb, [$self->relationships], 'type' =>
        'relationship', 'response' => $response, 'dataset' => $dataset, 
        'mdr' => $mdr);

    return $response;
}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

=head2 Internal Subroutines 

=over 4

=item do_register_all (CMDB, ITEM_AREF, ARGHASH)

Does the actual work of running B<register ()> against all items in ITEM_AREF
and processing errors accordingly.  This includes a nice error message telling
us how many errors there were out of how many attempted registrations (which is
why we're using B<Lingua::EN::Inflect>>.

=cut

sub do_register_all {
    my ($self, $cmdb, $item_aref, %args) = @_;
    my $response = $args{'response'};
    my ($count, $error_count) = (0, 0);
    foreach my $item (@$item_aref) { 
        $count++;
        my $error = $item->register ($cmdb, 'response' => $args{'response'},
            'dataset' => $args{'dataset'}, 'mdr_parent' => $args{'mdr'});
        if ($error) { 
            my $name = $item->name;
            $cmdb->logger_or_die->info ("error on $name: $error");
            $response->add_declined ($item, $error) if $error;
            $error_count++;
        }
    }
    $cmdb->logger_or_die->info (sprintf ("%s out of %s", 
        inflect ("NUM($error_count) registration PL_N(error)"),
        inflect ("NUM($count) PL_N($args{'type'})")));
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Lingua::EN::Inflect>, B<Remedy::CMDB::Deregister::ItemList>,
B<Remedy::CMDB::Deregister::RelationshipList>,
B<Remedy::CMDB::Deregister::Response>, B<Remedy::CMDB::Struct>

=head1 SEE ALSO

Remedy::CMDB(8), Remedy::CMDB::Query(8)

cmdb-server(3), cmdb-submit-deregister(1)

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
