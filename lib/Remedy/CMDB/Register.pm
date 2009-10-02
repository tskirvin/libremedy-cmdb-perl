package Remedy::CMDB::Register;
our $VERSION = "0.50.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Register - CMDB registration service

=head1 SYNOPSIS

    use Remedy::CMDB::Register;
    
    # $cmdb is an existing CMDB object - see Remedy::CMDB
    my $register = eval { Remedy::CMDB::register->read ('xml', 
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

Remedy::CMDB::Register is the heart of the CMDB registration service.  It
parses a piece of registration XML into four pieces of information: a list of
items to be registered, a list of relationships to be registered, a list of
deregistrations to be registered, and a parent MDR in which all of this work is
to be done.  From there, we offer functions to actually perform the work.

Remedy::CMDB::Register is a sub-class of B<Remedy::CMDB::Struct>, and inherits
many functions from there.

=cut

##############################################################################
### Configuration ############################################################
##############################################################################
# Nothing local.

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Lingua::EN::Inflect qw/inflect/;
use Remedy::CMDB::Item::List;
use Remedy::CMDB::Register::Response;
use Remedy::CMDB::Relationship::List;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item deregisterList (B<Remedy::CMDB::Deregister::List>)

A list of item deregisters to be registered.

=item itemList (B<Remedy::CMDB::Item::List>)

A list of items to be registered.

=item mdrId (I<MDR>)

The data source that this registration information came from.

=item relationshipList (B<Remedy::CMDB::Relationship::List>)

A list of item relationships to be registered.

=back

=cut

sub fields {
    'deregisterList'    => 'Remedy::CMDB::Deregister::List',
    'itemList'          => 'Remedy::CMDB::Item::List',
    'mdrId'             => '$',
    'relationshipList'  => 'Remedy::CMDB::Relationship::List',
}

=back

=cut

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
    $self->itemList         ();
    $self->relationshipList ();
    $self->deregisterList   ();
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

    if (my $deregisterlist = $xml->first_child ('deregisterList')) {
        my $obj = Remedy::CMDB::Deregister::List->read ('xml', 
            'source' => $deregisterlist, 'type' => 'object');
        return 'could not parse deregisterList' unless $obj;
        return $obj unless ref $obj;
        $self->deregisterList ($obj);
    }
    
    return;
}

=item tag_type ()

=cut

sub tag_type { 'registerRequest' }

=item text ()

=cut

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
    push @return, '', "Deregisters";
    foreach my $deregister (@{$self->deregisterList}) { 
        foreach ($deregister->text) { push @return, "  $_" }
    }

    wantarray ? @return : join ("\n", @return, '');
}

=back

=cut

##############################################################################
### Additional Functions #####################################################
##############################################################################

=head2 Additional Functions 

=over 4

=item deregisters ()

Returns an array of B<Remedy::CMDB::Deregister> objects, as recorded in
B<deregisterList ()>.

=cut

sub deregisters { 
    my ($self) = @_;
    return unless my $deregisterList = $self->deregisterList;
    return unless my $list = $deregisterList ->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

=item items ()

Like B<deregisters ()>, but returns an array of B<Remedy::CMDB::Item> objects
pulled from B<itemList ()>.

=cut

sub items {
    my ($self) = @_;
    return unless my $itemlist = $self->itemList;
    return unless my $list = $itemlist->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

=item register_all (CMDB, ARGHASH)

Registers all of the data stored in this object, in the following order: items,
relationships, deregisters.  

I<CMDB> is a connected B<Remedy::CMDB> object.  I<ARGHASH> is a hash of
arguments, which

=over 4

=item dataset I<DATASET>

Dataset that the data will be stored in within the CMDB.  Required.

=item mdr I<MDR>

Data source of the registered information.  Required.

=back

Returns a B<Remedy::CMDB::Register::Response> object populated with information
about what happened during this registration.

=cut

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
        'type' => 'relationship', 'response' => $response, 
        'dataset' => $dataset, 'mdr' => $mdr);

    $logger->debug ('registering all deregister requests');   
    $self->do_register_all ($cmdb, [$self->deregisters], 
        'type' => 'deregister', 'response' => $response, 
        'dataset' => $dataset, 'mdr' => $mdr);
        
    return $response;
}

=item relationships ()

Like B<deregisters ()>, but returns an array of B<Remedy::CMDB::Relationship>
objects pulled from B<relationshipList ()>.

=cut

sub relationships {
    my ($self) = @_;
    return unless my $relationshiplist = $self->relationshipList;
    return unless my $list = $relationshiplist->list;
    return unless ref $list && scalar @$list;
    return @$list;
}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

### do_register_all (CMDB, ITEM_AREF, ARGHASH)
# Does the actual work of running register () against all items in ITEM_AREF
# and processing errors accordingly.  This includes a nice error message
# telling us how many errors there were out of how many attempted
# registrations.  

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

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Lingua::EN::Inflect>, B<Remedy::CMDB::Deregister::List>,
B<Remedy::CMDB::Item::List>, Remedy::CMDB::Register::Response>,
B<Remedy::CMDB::Relationship::List>, B<Remedy::CMDB::Struct>

=head1 SEE ALSO

Remedy::CMDB(8), Remedy::CMDB::Query(8)

cmdb-server(3), cmdb-submit(1)

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
