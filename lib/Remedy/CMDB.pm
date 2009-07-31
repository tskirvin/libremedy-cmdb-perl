package Remedy::CMDB;
our $VERSION = "0.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

=head1 VARIABLES

These variables primarily hold human-readable translations of the status,
impact, etc of the ticket; but there are a few other places for customization.

=over 4

=item $CONFIG

=cut

=back

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;

use Remedy;
use Remedy::CMDB::Config;
use Remedy::CMDB::Log;

struct 'Remedy::CMDB' => {
    'config'    => 'Remedy::CMDB::Config',
    'logobj'    => 'Remedy::CMDB::Log',
    'remedy'    => 'Remedy',
};

##############################################################################
### Subroutines ##############################################################
##############################################################################

sub connect {
    my ($class, %args) = @_;
    my $self = $class->new;

    ## Load and store configuration information
    my $config = $args{'config'} || '';
    my $conf = ref $config ? $config 
                           : Remedy::CMDB::Config->load ($config);
    $self->config ($conf);

    ## Get and save the logger
    $self->logobj ($self->config->log);
    if (my $debug = $args{'debug'}) { $self->logobj->more_logging ($debug); }

    ## From now on, we can print debugging messages when necessary
    my $logger = $self->logger_or_die ('no logger at init');

    my $remedy = eval { Remedy->connect ('config' => $conf->remedy_config) }
        or $logger->logdie ("couldn't connect to database: $@");
    $logger->logdie ($@) if $@;

    $self->remedy ($remedy);
    $remedy->logobj ($self->logobj);        

    return $self;
}

=item register_item (ITEM, ARGHASH)

=cut

sub register_item {
    my ($self, $item, %args) = @_;

    ## Make sure we're connected to remedy.  Perhaps we want to make this less
    ## nasty if we don't have them?
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    my $response   = $args{'response'}   or return 'no response offered'; 
    my $dataset    = $args{'dataset'}    or return 'no dataset offered';
    my $mdr_parent = $args{'mdr_parent'} or return 'no parent mdr offered';

    my $localId  = $item->localId  or return 'no localId';
    my $datatype = $item->datatype or return 'no datatype';
    my $mdrId    = $item->mdrId    or return 'no mdrId';
    my $record   = $item->record   or return 'no record';

    my $externalId = join ('@', $localId, $mdrId);

    my $data = $record->data or return 'no record data';

    return 'mdrId does not match parent mdrId' unless $mdrId eq $mdr_parent;

    my $class = $self->translate_class ($datatype) 
        or return "invalid class: $datatype";

    my $name = $localId;

    my @changes;

    my $obj;
    my @obj = $self->find_item ($item, $class);
    if (! scalar @obj) { 
        $logger->debug ("creating new object '$name' in '$dataset'");
        $obj = $self->create ($class);
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

    if (scalar @changes) {
        $logger->debug ("saving entry for '$name'");

        ## for some reason, we're getting errors on save that aren't... real.
        if (my $error = $obj->save) {
            my $sess_error = $session->error;
            my $full_error = join ('', $error, $sess_error);
            return $full_error;
        }
        $logger->debug ("registering translation table entry for '$name'");
        my $instanceid = $obj->get ('InstanceId')
            or return "could not find instance ID after saving";
        if (my $translate_error = $self->register_translation ($item,
            $instanceid)) {
            $logger->info ($translate_error);
            return $translate_error;
        }

    }

    $response->add_accepted ($item, $string, 'obj' => $obj);
    return;
}

=item register_relationship (RELATIONSHIP, ARGHASH)

=over 2

=item response

=item dataset

=item mdr_parent

=back

=cut

sub register_relationship {
    my ($self, $relationship, %args) = @_;

    return 'not currently working';

    ## Make sure we have all of the necessary bits about the relationship
    return 'no relationship' unless ($relationship && ref $relationship);
    my $source = $relationship->source or return 'no relationship source';
    my $target = $relationship->target or return 'no relationship target';
    my $record = $relationship->record or return 'no relationship record';

    my $datatype = $record->datatype or return 'no datatype';

    ## Make sure we have what we need out of the arguments
    my $response   = $args{'response'}   or return 'no response offered'; 
    my $dataset    = $args{'dataset'}    or return 'no dataset offered';
    my $mdr_parent = $args{'mdr_parent'} or return 'no parent mdr offered';

    ## Make sure we're connected to remedy as well.  Perhaps we want to make
    ## this less nasty if we don't have them?
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    ## Confirm that the source and target endpoints exist
    my $baseclass = $self->translate_class ('baseElement')
        or return "invalid class: baseElement";

    my $source_item = $self->find_item ($source, $baseclass, 
        'mdr_parent' => $mdr_parent) or return "source does not exist"; 
    my $target_item = $self->find_item ($target, $baseclass, 
        'mdr_parent' => $mdr_parent) or return "target does not exist"; 
        
    my $class = $self->translate_class ($datatype) 
        or return "invalid class: $datatype";
    
    return;
}

=item find_item (ITEM, CLASS, ARGHASH)

I<ITEM> is a B<Remedy::CMDB::InstanceID> object.

=cut

sub find_item {
    my ($self, $item, $class, %args) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    ## Make sure we have the information out of $item that we'll need.
    my $mdrId   = $item->mdrId   or return;
    my $localId = $item->localId or return;

    ## What class are we going to be searching?
    $class ||= 'baseElement';
    return unless my $translate = $class = $self->translate_class ($class);

    my $instanceid = $self->translate_mdr_to_instanceid ($mdrId, $localId)
        or return;

    my $string = "$instanceid in $translate";
    $logger->debug ("searching for $string in $class");
    my @items = $self->read ($translate, {'InstanceId' => $instanceid});
    if (scalar @items == 0) {
        $logger->debug ("no matches for $string");
        return;
    } 

    return wantarray ? @items : \@items;
}

sub register_translation { undef } 
sub register_translation_old {
    my ($self, $item, $instanceid) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    return if $self->translate_instanceid_to_mdr ($instanceid);

    ## Make sure we have the information out of $item that we'll need.
    my $mdrId   = $item->mdrId   or return 'no mdrId';
    my $localId = $item->localId or return 'no localId';

    my $class = $self->translate_class ('translate') 
        or return 'no translate table';

    return 'no instanceId' unless $instanceid;
    
    my $new = $self->create ($class);
    $new->set ('CI Instance ID' => $instanceid);
    $new->set ('MDR ID'         => $mdrId);
    $new->set ('Local ID'       => $localId);

    if (my $error = $new->save) {
        my $text = "error on translation save: $error";
        return $text;
    }

    return;
}

sub translate_instanceid_to_mdr {
    my ($self, $instanceid) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    unless ($instanceid) { 
        $logger->warn ('no instanceid offered');
        return;
    }

    my $class = $self->translate_class ('translate') or return;

    my %search = ('External Instance ID' => $instanceid);
    my $string = "translation of $instanceid";

    $logger->debug ("searching for $string");
    my @translate = $self->read ($class, \%search);
    if (scalar @translate == 0) {
        $logger->debug ("no matches for $string");
        return;
    } elsif (scalar @translate > 1) {
        $logger->info ("too many matches for $string");
        return;
    } 

    my $entry = $translate[0];

    return ($entry->get ('MDR ID'), $entry->get ('Local ID'));
}

sub translate_mdr_to_instanceid {
    my ($self, $mdr, $local) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    my $class = $self->translate_class ('translate') or return;

    my %search = ('Local ID' => $local, 'MDR ID' => $mdr);
    my $string = "translation of $local\@$mdr";

    $logger->debug ("searching for $string");
    my @translate = $self->read ($class, \%search);
    if (scalar @translate == 0) {
        $logger->debug ("no matches for $string");
        return;
    } elsif (scalar @translate > 1) {
        $logger->info ("too many matches for $string");
        return;
    } 

    my $entry = $translate[0];
    return $entry->get ('CI Instance ID');
}



sub create { shift->remedy_or_die->create (@_) }
sub read   { shift->remedy_or_die->read (@_) }

sub logger { shift->logobj_or_die->logger (@_) }

sub translate_class { shift->config_or_die->class_human_to_remedy (@_) }

sub config_or_die { shift->_or_die ('config', "no configuration", @_) }
sub logobj_or_die { shift->_or_die ('logobj', "no logger",        @_) }
sub logger_or_die { shift->_or_die ('logger', "no logger",        @_) }
sub remedy_or_die { shift->_or_die ('remedy', "no remedy",        @_) }

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

### _or_die (TYPE, ERROR, EXTRATEXT, COUNT)
# Helper function for Class::Struct accessors.  If the value is not defined -
# that is, it wasn't set - then we will immediately die with an error message
# based on a the calling function (can go back extra levels by offering
# COUNT), a generic error message ERROR, and a developer-provided, optional
# error message EXTRATEXT.  
sub _or_die {
    my ($self, $type, $error, $extra, $count) = @_;
    return $self->$type if defined $self->$type;
    $count ||= 0;

    my $func = (caller ($count + 2))[3];    # default two levels back

    chomp $extra if defined $extra;
    my $fulltext = sprintf ("%s: %s", $func, $extra ? "$error ($extra)"
                                                    : $error);
    die "$fulltext\n";
}

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Class::Struct>, B<Remedy>

=head1 SEE ALSO

Remedy(8)

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
