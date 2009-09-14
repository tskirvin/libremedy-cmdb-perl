package Remedy::CMDB::Relationship;
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

use Remedy::CMDB::Relationship::Record;
use Remedy::CMDB::Relationship::Source;
use Remedy::CMDB::Relationship::Target;
use Remedy::CMDB::Relationship::Response;
use Remedy::CMDB::Relationship::DataSource;

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

=item record

=item source

=item target

=back

=cut

sub fields {
    'instanceId' => 'Remedy::CMDB::Item::InstanceID',
    'record'     => 'Remedy::CMDB::Relationship::Record',   # TODO: '$'?
    'source'     => 'Remedy::CMDB::Relationship::Source',
    'target'     => 'Remedy::CMDB::Relationship::Target',
}

=item id ()
            
=cut
            
sub id      { shift->instanceId->id }
    
=item localId ()

=cut
    
sub localId { shift->instanceId->localId }
    
=item mdrId () 
    
=cut
    
sub mdrId   { shift->instanceId->mdrId   }
        
sub source_id       { shift->source->id }
sub source_localId  { shift->source->localId }
sub source_mdrId    { shift->source->mdrId }

sub target_id       { shift->source->id }
sub target_localId  { shift->source->localId }
sub target_mdrId    { shift->source->mdrId }

=back

=cut

##############################################################################
### Related Objects ##########################################################
##############################################################################

=head2 Related Objects 

=over 4

=item response ()

=cut

sub response { shift; Remedy::CMDB::Relationship::Response->new (@_) }

=item source_data ()

=cut

sub source_data {
    my ($self) = @_;
    my $src = Remedy::CMDB::Relationship::DataSource->new (
        'source' => $self->source, 'target' => $self->target);
    return $src;
}

=back

=cut

##############################################################################
### Data Manipulation ########################################################
##############################################################################

=head2 Data Manipulation

=over 4

=item find (CMDB, ARGHASH)

=cut

sub find {
    my ($self, $cmdb, %args) = @_;
    my $logger = $cmdb->logger_or_die;
    
    ## Make sure we have the information out of $item that we'll need.
    my $source = $cmdb->find_item ($self->source) 
        or $logger->logdie ('no source');
    my $target = $cmdb->find_item ($self->target)
        or $logger->logdie ('no target');
        
    my %match = ('Source.DatesetId'       => $source->get ('DatasetId'),
                 'Source.InstanceId'      => $source->get ('InstanceId'),
                 'Destination.DatasetId'  => $target->get ('DatasetId'),
                 'Destination.InstanceId' => $target->get ('InstanceId'));
                 
    ## What class are we going to be searching?
    my $class = $args{'class'} || 'baseRelationship';
    my $translate_class = $cmdb->translate_class ($class) ||
        $logger->logdie ("no translation of class '$class'");
    
    my $string = sprintf ("relationship between %s and %s", 
        $self->source->text, $self->target->text);
    $logger->debug ("searching for $string");
    my @items = $cmdb->read ($translate_class, \%match);
    if (scalar @items == 0) {
        $logger->debug ("no matches for $string");
        return;
    }  
    
    return wantarray ? @items : \@items;
}

=item register (CMDB, ARGHASH)

=over 4

=item dataset I<DATASET>

=item mdr_parent I<MDR>

=item response I<RESPONSE>

=back

=cut

# known to not work yet
sub register { 
    my ($self, $cmdb, %args) = @_;
    return 'no cmdb connection' unless $cmdb && $cmdb->remedy;

    my $logger  = $cmdb->logger_or_die ('no logger at item registration');
    my $remedy  = $cmdb->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    ## Make sure we have what we need out of the arguments
    my $response   = $args{'response'}   or return 'no response offered';
    my $dataset    = $args{'dataset'}    or return 'no dataset offered';
    my $mdr_parent = $args{'mdr_parent'} or return 'no parent mdr offered';

    ## Make sure we have all of the necessary bits about the relationship
    my $source = $self->source or return 'no relationship source';
    my $target = $self->target or return 'no relationship target';
    my $record = $self->record or return 'no relationship record';
    
    my $data     = $record->data     or return 'no record data';
    my $datatype = $record->datatype or return 'no record datatype';
    
    ## Confirm that the source and target endpoints exist
    my $baseclass = $cmdb->translate_class ('baseElement')
        or return 'invalid class: baseElement';
    
    my $src_item = $cmdb->find_item ($source, 'class' => $baseclass,
        'mdr_parent' => $mdr_parent) or return "source does not exist";
    my $tgt_item = $cmdb->find_item ($target, 'class' => $baseclass, 
        'mdr_parent' => $mdr_parent) or return "target does not exist";
        
    my $class = $cmdb->translate_class ($datatype)
        or return "invalid class: $datatype";
        
    my @changes;
    
    my $obj;
    my @obj = $self->find ($cmdb, 'class' => $class);
    if (! scalar @obj) { 
        $logger->debug ("creating new relationship in '$dataset'");
        $obj = $cmdb->create ($class);
        $obj->set ('Source.DatasetId'       => $dataset);
        $obj->set ('Source.InstanceId'      => $src_item->get ('InstanceId'));
        $obj->set ('Destination.DatasetId'  => $dataset);
        $obj->set ('Destination.InstanceId' => $tgt_item->get ('InstanceId'));
        $obj->set ('DatasetId'              => $dataset);
        push @changes, "new relationship";
    } elsif (scalar @obj > 1) { 
        return 'too many relationships found';
    } else {
        $logger->debug ("found existing relationship in '$dataset'");
        $obj = $obj[0];
    }   
    
    my $name = join (' -> ', $obj->get ('Source.InstanceId'),
        $obj->get ('Destination.InstanceId'));
        
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
    
    if (scalar @changes) {
        $logger->debug ("saving entry for '$name'");
        if (my $error = $obj->save) {
            my $sess_error = $session->error;
            my $full_error = join ('', $error, $sess_error);
           return $full_error;
        }   
        my $instanceid = $obj->get ('InstanceId')
            or return "could not find instance ID after saving";
    }   
    
    $response->add_accepted ($self, $string, 'obj' => $obj);
    return;
}

=back

=cut

##############################################################################
### XML Manipulation #########################################################
##############################################################################

=head2 XML Manipulation

=over 4

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be relationship' unless 
        (lc $xml->tag eq 'relationship');

    foreach my $field (qw/source target record/) {
        my $id;
        foreach my $item ($xml->children ($field)) {
            return 'too many items in $field' if $id;
            my $obj = ('Remedy::CMDB::Relationship::' . ucfirst $field)->read 
                ('xml', 'source' => $item, 'type' => 'object');
            return 'no object created' unless $obj;
            return $obj unless ref $obj;
            $id = $obj;
        }
        $self->$field ($id);
        return "no $field" unless $self->$field;
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

=item tag_type ()

I<relationship>

=cut

sub tag_type { 'relationship' }

=item text ()

=cut

sub text {
    my ($self, %args) = @_;
    my @return;
    foreach my $field (qw/source target/) {
        push @return, sprintf ("  %s: %s", ucfirst $field, 
            $self->$field->text);
    }
    if (my $record = $self->record) { 
        foreach ($record->text) { push @return, '  ' . $_; }
    }
    return wantarray ? @return : join ("\n", @return, '');
}

=cut

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
