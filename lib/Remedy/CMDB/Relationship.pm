package Remedy::CMDB::Relationship;
our $VERSION = "0.50";

=head1 NAME

Remedy::CMDB::Relationship - a single relationship in the CMDB

=head1 SYNOPSIS

    use Remedy::CMDB::Relationship

=head1 DESCRIPTION

Remedy::CMDB::Relationship records information about a single relationship
entry in the CMDB, and offers functionality to both search the database for
that information and to update the information when appropriate.

Remedy::CMDB::Relationship is a sub-class of B<Remedy::CMDB::Struct>, and
inherits many functions from there.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Relationship::InstanceId;
use Remedy::CMDB::Relationship::Record;
use Remedy::CMDB::Relationship::Response;
use Remedy::CMDB::Relationship::Source;
use Remedy::CMDB::Relationship::Target;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item instanceId ($)

Information about where the data is stored in the database.  Generally a
B<Remedy::CMDB::Relationship::InstanceId> object.

=item record B<Remedy::CMDB::Relationship::Record>

Information about the data itself. 

=item source B<Remedy::CMDB::Relationship::Source>

Information about where the relationship source is in the database.

=item target B<Remedy::CMDB::Relationship::Target>

Information about where the relationship target is in the database.

=back

=cut

sub fields {
    'instanceId' => '$',
    'record'     => 'Remedy::CMDB::Relationship::Record',   # TODO: '$'?
    'source'     => 'Remedy::CMDB::Relationship::Source',
    'target'     => 'Remedy::CMDB::Relationship::Target',
}

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.

=over 4

=item fields 

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be relationship' unless 
        (lc $xml->tag eq 'relationship');

    foreach my $field (qw/source target record instanceId/) {
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

=back

=cut

##############################################################################
### Related Objects ##########################################################
##############################################################################

=head2 Related Objects 

=over 4

=item response (ARGS)

Creates a B<Remedy::CMDB::Relationship::Response> object based on the argument
array B<ARGS>.

=cut

sub response { shift; Remedy::CMDB::Relationship::Response->new (@_) }

=item source_data () 

Same as B<instanceId>.

=cut

sub source_data { shift->instanceId }

=back

=cut



##############################################################################
### Data Manipulation ########################################################
##############################################################################

=head2 Data Manipulation

=over 4

=item find (CMDB, ARGHASH)

Searches I<CMDB> for the current relationship.  What this really means: we find
the appropriate internal Instance ID by running the local mdrId and localId
through B<Remedy::CMDB::translate_instanceid ()>, and then search the remedy
database for that particular ID.

Arguments that we can take through I<ARGHASH>:

=over 4

=item class I<CLASS>

What class/table should we search?  Defaults to 'baseRelationship'.

=back

On success, returns all matching relationship (or, if requested in a scalar
context, only the first item).  On failure, returns undef.  Dies if the search
went badly in some way.

=cut

sub find {
    my ($self, $cmdb, %args) = @_;
    my $logger = $cmdb->logger_or_die;

    ## Make sure we have the information out of $item that we'll need.
    my $source = $cmdb->find_item ($self->source) 
        or $logger->logdie ('no source');
    my $target = $cmdb->find_item ($self->target)
        or $logger->logdie ('no target');

    my $mdrId   = $self->mdrId   or $logger->logdie ('no mdrId');
    my $localId = $self->localId or $logger->logdie ('no localid');
    
    my $class = $args{'class'} || 'baseRelationship';
    my $translate_class = $cmdb->translate_class ($class) ||
        $logger->logdie ("no translation of class '$class'");
        
    my $instanceid = eval { $cmdb->translate_instanceid ($mdrId, $localId,
        %args) };
    if ($@) { 
        $logger->logdie ("failed to translate MDR info: $@") 
    } elsif (!$instanceid) { 
        $logger->debug ("no match found in $translate_class");
        return;
    }
                 
    my $string = sprintf ("%s in %s (from %s to %s)", $instanceid, 
        $translate_class, $self->source->text, $self->target->text);
    $logger->debug ("searching for $string");
    my @items = $cmdb->read ($translate_class, {'InstanceId' => $instanceid});
    if (scalar @items == 0) {
        $logger->fatal ("no matches for $string");
        $logger->logdie ("found in translation table, but no matching entry\n");
    }  
    
    return wantarray ? @items : \@items;
}

=item register (CMDB, ARGHASH)

Registers the current object into the CMDB.  This consists of the following
general steps:

=over 4

=item 0.  Data Verification

Look for excuses to abort now, before we actually hit the database.

=item 1.  Looks for the current object in the CMDB.

If the item is found, then we'll update it; if not, we'll create a new one.

=item 2.  Figures out what changes we're making to the data.

New objects are obviously new objects; but existing objects may not have any
real changes.

=item 3.  Saves the changes, if applicable.

If there are no changes, then we won't save.

=item 4.  Update the translation table.

Even if there are no changes, we want to tell the translation table that we at
least tried, so we can keep track of the last time this data was checked in.

=back

Takes the following functions from I<ARGHASH>, all of which are required:

=over 4

=item dataset I<DATASET>

The dataset that we're registering this data into.  Should match the MDR (but
we don't have the right information at this point to confirm that.)

=item mdr_parent I<MDR_PARENT>

The parent MDR that the parent object thinks we're registering under.  If this
doesn't match the MDR of the data that we're going to register, then we will
fail.

=item response B<Remedy::CMDB::Register::Response>

An object that contains information about all attempted registrations this run.

=back

On success, updates the B<Remedy::CMDB::Register::Response> object and 
returns undef.  On failure, returns a string explaining what went
wrong with the registration.

=cut

sub register { 
    my ($self, $cmdb, %args) = @_;
    return 'no cmdb connection' unless $cmdb && $cmdb->remedy;
    my $logger  = $cmdb->logger_or_die ('no logger at item registration');

    ## Parse arguements from %args
    my $response   = $args{'response'}   or return 'no response offered';
    my $dataset    = $args{'dataset'}    or return 'no dataset offered';
    my $mdr_parent = $args{'mdr_parent'} or return 'no parent mdr offered';

    ## Make sure we have all the local object info we'll need to proceed.
    my $localId = $self->localId or return 'no localId';
    my $mdrId  = $self->mdrId   or return 'no mdrId';
    my $source = $self->source  or return 'no relationship source';
    my $target = $self->target  or return 'no relationship target';
    my $record = $self->record  or return 'no relationship record';
    
    my $data     = $record->data     or return 'no record data';
    my $datatype = $record->datatype or return 'no record datatype';

    ## Do we know how to deal with this particular class?
    my $class = $cmdb->translate_class ($datatype)
        or return "invalid class: $datatype";
    
    ## Confirm that the source and target endpoints exist
    my $baseclass = $cmdb->translate_class ('baseElement')
        or return 'invalid class: baseElement';
    
    my $src_item = eval { $cmdb->find_item ($source, 'class' => $baseclass,
        'mdr_parent' => $mdr_parent, 'dataset' => $dataset) };
    return "error on src search: $@" if $@;
    return "source does not exist" unless $src_item;;

    my $tgt_item = eval { $cmdb->find_item ($target, 'class' => $baseclass, 
        'mdr_parent' => $mdr_parent, 'dataset' => $dataset) };
    return "error on tgt search: $@" if $@;
    return "target does not exist" unless $tgt_item;;
    
    return 'mdrs of source and target do not match' 
        unless $src_item->get ('DatasetId') eq $tgt_item->get ('DatasetId');
        
    ## Look for existing entries.
    my @obj = eval { $self->find ($cmdb, 'class' => $class, 
        'dataset' => $dataset) };
    if ($@) { 
        chomp $@;
        $logger->info ("find error: $@");
        return $@;
    }

    ## Decide if we're using an existing object, or making a new one
    my ($obj, @changes, @fields);
    if (! scalar @obj) { 
        $logger->debug ("creating new relationship in '$dataset'");
        $obj = $cmdb->create ($class);
        $obj->set ('Source.DatasetId'       => $dataset);
        $obj->set ('Source.InstanceId'      => $src_item->get ('InstanceId'));
        $obj->set ('Destination.DatasetId'  => $dataset);
        $obj->set ('Destination.InstanceId' => $tgt_item->get ('InstanceId'));
        $obj->set ('DatasetId'              => $dataset);
        ## append the timestamp to new objects.
        my $externalId = join ('.', time, join ('@', $localId, $mdrId));
        $obj->set ('InstanceId' => $externalId);
        push @changes, "new relationship";
    } elsif (scalar @obj > 1) { 
        return 'too many relationships found';
    } else {
        $logger->debug ("found existing relationship in '$dataset'");
        $obj = $obj[0];
    }   
    
        
    ## Parse the local data hash and figure out what changes are necessary
    foreach my $key (sort keys %{$data}) {
        if ($key eq 'DatasetId') {
            $logger->debug ("skipping key $key");
            next;
        } elsif ($key eq 'InstanceId' || $key eq 'MarkAsDeleted') {
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

    ## What changes have we made?  Let's make it human-readable.
    my $name = join (' -> ', $obj->get ('Source.InstanceId'),
        $obj->get ('Destination.InstanceId'));
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
    
    ## Record our success and exit.
    $response->add_accepted ($self, $string, 'obj' => $obj);
    return;
}

=back

=cut

##############################################################################
### Miscellaneous ############################################################
##############################################################################

=head2 Miscellaneous 

=over 4

=item id ()

Returns B<id ()> from B<instanceId ()>.
    
=item localId ()

Returns B<localId ()> from B<instanceId ()>.

=item mdrId () 

Returns B<mdrId ()> from B<instanceId ()>.

=cut
            
sub id      { shift->instanceId->id }
sub localId { shift->instanceId->localId }
sub mdrId   { shift->instanceId->mdrId   }

=item name ()

Same as B<id ()>.

=cut

sub name { shift->id (@_) }

=item source_id ()

Returns B<id ()> from B<source ()>.

=item source_localId ()

Returns B<localId ()> from B<source ()>.

=item source_mdrId ()

Returns B<mdrId ()> from B<source ()>.

=cut
        
sub source_id       { shift->source->id }
sub source_localId  { shift->source->localId }
sub source_mdrId    { shift->source->mdrId }

=item target_id ()

Returns B<id ()> from B<target ()>.

=item target_localId ()

Returns B<localId ()> from B<target ()>.

=item target_mdrId ()

Returns B<mdrId ()> from B<target ()>.

=cut

sub target_id       { shift->target->id }
sub target_localId  { shift->target->localId }
sub target_mdrId    { shift->target->mdrId }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Relationship::InstanceId>,
B<Remedy::CMDB::Relationship::Record>,
B<Remedy::CMDB::Relationship::Response>,
B<Remedy::CMDB::Relationship::Source>,
B<Remedy::CMDB::Relationship::Target>,
B<Remedy::CMDB::Struct>

=head1 SEE ALSO

Remedy::CMDB::Item(8), Remedy::CMDB::Deregister(8)

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
