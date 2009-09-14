package Remedy::CMDB::Item;
our $VERSION = "0.01";

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

use Remedy::CMDB::Item::Record;
use Remedy::CMDB::Item::InstanceID;
use Remedy::CMDB::Item::DataSource;
use Remedy::CMDB::Item::Response;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=head2 Basic Data Structures

=over 4

=item fields 

=over 4

=back

=cut

sub fields {
    # 'instanceId' => 'Remedy::CMDB::Item::InstanceID',
    'instanceId' => '$',    # generally Remedy::CMDB::Item::InstanceID
    'record'     => '$',
}

=item datatype ()

=cut

sub datatype { shift->record->datatype }

=item id ()

=cut

sub id      { shift->instanceId->id }

=item localId ()

=cut

sub localId { shift->instanceId->localId }

=item mdrId ()

=cut

sub mdrId   { shift->instanceId->mdrId   }

=back

=cut

##############################################################################
### Related Objects ##########################################################
##############################################################################

=head2 Related Objects

=over 4

=item response ()

=cut

sub response { shift; Remedy::CMDB::Item::Response->new (@_) }

=item source_data ()

=cut

sub source_data {
    my ($self) = @_;
    my $src = Remedy::CMDB::Item::DataSource->new ('instanceId' => 
        $self->instanceId);
    return $src;
}

=back

=cut

##############################################################################
### Data Manipulation ########################################################
##############################################################################


sub find {
    my ($self, $cmdb, %args) = @_;
    my $logger  = $cmdb->logger_or_die;

    my $mdrId   = $self->mdrId   or $logger->logdie ('no mdrId');
    my $localId = $self->localId or $logger->logdie ('no localid');

    ## What class are we going to be searching?
    my $class = $args{'class'} || 'baseElement';
    my $translate_class = $cmdb->translate_class ($class) ||
        $logger->logdie ("no translation of class '$class'");

    my $instanceid;
    { 
        local $@;
        $instanceid = eval { $cmdb->translate_mdr_to_instanceid ($mdrId, 
            $localId) };
        if ($@) { $logger->logdie ("failed to translate MDR info: $@") }
        elsif (!$instanceid) { 
            $logger->debug ("no match found in $translate_class");
            return;
        }
    }

    my $string = "$instanceid in $translate_class";
    $logger->debug ("searching for $string in $class");
    my @items = $cmdb->read ($translate_class, {'InstanceId' => $instanceid});
    if (scalar @items == 0) {
        $logger->debug ("no matches for $string");
        return;
    } 

    return wantarray ? @items : $items[0];
}

## this realy needs to be split up into sub-functions.

sub register {
    my ($self, $cmdb, %args) = @_;
    return 'no cmdb connection' unless $cmdb && $cmdb->remedy;
    my $logger  = $cmdb->logger_or_die ('no logger at item registration');

    my $response   = $args{'response'};
    my $dataset    = $args{'dataset'}    or return 'no dataset offered';
    my $mdr_parent = $args{'mdr_parent'} or return 'no parent mdr offered';

    my $name     = $self->localId  or return 'no localId';
    my $datatype = $self->datatype or return 'no datatype';
    my $mdrId    = $self->mdrId    or return 'no mdrId';
    my $record   = $self->record   or return 'no record';

    return 'mdrId does not match parent mdrId' unless $mdrId eq $mdr_parent;

    # TODO: this should be a function somewhere
    my $externalId = join ('.', time, join ('@', $name, $mdrId));

    my $data = $record->data or return 'no record data';

    my $class = $cmdb->translate_class ($datatype) 
        or return "invalid class: $datatype";

    my @changes;

    my @obj;
    {
        local $@;
        @obj = eval { $self->find ($cmdb, 'class' => $class) };
        if ($@) { 

        }
    }
    my $obj;
    if (! scalar @obj) { 
        $logger->debug ("creating new object '$name' in '$dataset'");
        $obj = $cmdb->create ($class);
        $obj->set ('DatasetId'  => $dataset);
        $obj->set ('InstanceId' => $externalId);
        push @changes, "new object";
    } elsif (scalar @obj > 1) { 
        return 'too many objects found';
    } else {
        $logger->debug ("found existing object '$name' in '$dataset'");
        $obj = $obj[0];
    }

    my @fields;
    foreach my $key (sort keys %{$data}) {
        if ($key eq 'DatasetId') {
            $logger->debug ("skipping key $key");
            next;
        } elsif ($key eq 'InstanceId') {
            $logger->debug ("key $key should not be written to from here");
            return "tried to write to $key";
        }
        return "$datatype: '$key' is invalid" unless $obj->validate ($key);
        my $value = $$data{$key} || '';
        my $orig  = $obj->get ($key);
        if (defined $orig && $value eq $orig) {
            $logger->all (sprintf ("%20.20s: no change", $key));
        } else {
            $logger->all (sprintf ("%20.20s: set to '%s'", $key, $value));
            $obj->set ($key, $value);
            push @fields, $key;
        }
    }

    push @changes, "updated " . join (", ", @fields) if scalar @fields;
    my $string = join ('; ', @changes) || 'no changes';

    $logger->info ("$name: $string");

    ## Save out the changes, if any.
    if (scalar @changes) {
        $logger->debug ("saving entry for '$name'");
        if (my $error = $obj->save) {
            my $sess_error = $cmdb->remedy_or_die->session_or_die->error;
            my $full_error = join ('', $error, $sess_error);
            return $full_error;
        }
    }
    my $instanceid = $obj->get ('InstanceId')
            or return "could not find instance ID after saving";

    ## Register the fact that we looked at all in the translation table
    $logger->debug ("registering translation entry for '$name'");
    my %translate = ('instanceId' => $instanceid, 'datasetId' => $dataset);
    if (my $trans_error = $cmdb->register_translation (%translate)) {
        $logger->info ($trans_error);
        return $trans_error;
    }

    $response->add_accepted ($self, $string, 'obj' => $obj) if $response;
    return;
}

##############################################################################
### XML Manipulation #########################################################
##############################################################################

=head2 XML Manipulation

=over 4

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be item' unless (lc $xml->tag eq 'item');

    {
        my $id;
        foreach my $item ($xml->children ('instanceId')) {
            return 'too many instanceIds' if $id;
            my $obj = Remedy::CMDB::Item::InstanceID->read ('xml',
                'source' => $item, 'type' => 'object');
            return 'no object created' unless $obj;
            return $obj unless ref $obj;
            $id = $obj;
        }
        $self->instanceId ($id);
        return "no instanceId" unless $self->instanceId;
    }

    {
        my $record;
        foreach my $item ($xml->children ('record')) {
            return 'too many objects' if $record;
            my $obj = Remedy::CMDB::Item::Record->read ('xml', 
                'source' => $item, 'type' => 'object');
            return "no object created" unless $obj;
            return $obj unless ref $obj;
            $record = $obj;
        }
        $self->record ($record);
    }

    return;
}

=back

=cut

##############################################################################
### Reporting Functions ######################################################
##############################################################################

=head2 Reporting Functions

=over 4

=item tag_type 

I<item>

=cut

sub tag_type { 'item' }

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
