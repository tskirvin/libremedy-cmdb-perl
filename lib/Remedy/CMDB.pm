package Remedy::CMDB;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB - an interface to the Remedy CMDB

=head1 SYNOPSIS

    use Remedy::CMDB;


=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################
## Configuration all goes into the Remedy::CMDB::Config object.

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

=item register_item (ITEM, ARGUMENTS)

Invokes B<register (ARGUMENTS)> on I<ITEM>.

=cut

sub register_item {
    my ($self, $item, @rest) = @_;
    return $item->register ($self, @rest);
}

=item register_relationship (RELATIONSHIP, ARGHASH)

=over 2

=item response

=item dataset

=item mdr_parent

=back

=cut

sub register_relationship {
    my ($self, $relationship, @rest) = @_;
    return $relationship->register ($self, @rest);
}

=item find_item (OBJECT, ARGHASH)

I<OBJECT> is any object that contains the functions C<mdrId ()> and C<localId
()>.  

=cut

sub find_item {
    my ($self, $obj, @rest) = @_;
    my $item = Remedy::CMDB::Item->new ('instanceId' => $obj);
    return $item->find ($self, @rest);
}

=item find_relationship (SOURCE, TARGET, ARGHASH)

=cut

sub find_relationship {
    my ($self, $source, $target, @rest) = @_;
    my $relationship = Remedy::CMDB::Relationship->new ('source' => $source, 
        'target' => $target);
    return $relationship->find ($self, @rest);
}

sub find_translation {
    my ($self, $translate, $class, %args) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    my $ext_id  = $translate->get ('Internal InstanceId'),
    my $dataset = $translate->get ('DatasetId');

    my %match = ('Internal InstanceId' => $ext_id, 'DatasetId' => $dataset);

    ## What class are we going to be searching?
    $class ||= 'translate';
    return unless my $t_class = $self->translate_class ($class);

    my $string = "translation of $ext_id in dataset $dataset";
    $logger->debug ("searching for $string");
    my @items = $self->read ($t_class, {%match});
    if (scalar @items == 0) {
        $logger->debug ("no matches for $string");
        return;
    } 

    return wantarray ? @items : \@items;
    
}

sub register_translation {
    my ($self, %fields) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    my $instanceId = $fields{'instanceId'} || return 'no instanceId';
    my $datasetId  = $fields{'datasetId'}  || return 'no datasetId';

    my $name = join ('@', $instanceId, $datasetId);

    my $class = $self->translate_class ('translate') 
        or return 'no translate table';

    my $stub = $self->create ($class);
    $stub->set ('Internal InstanceId', $instanceId);
    $stub->set ('DatasetId', $datasetId);

    my $obj;
    my @obj = $self->find_translation ($stub);
    if    (! scalar @obj)   { return 'no existing entry found' }
    elsif (scalar @obj > 1) { return 'too many entries found' }
    else {
        $logger->debug ("found matching translation table entry for $name");
        $obj = $obj[0];
    }
    $obj->set ('Last Seen', time);
    if (my $error = $obj->save) {
        my $text = "error on translation save: $error";
        return $text;
    }

    return;
}

sub translate_mdr_to_instanceid {
    my ($self, $mdr, $local) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    $logger->debug ("translate_mdr_to_instanceid ($mdr, $local)");

    my $class = $self->translate_class ('translate') or return;

    my %search = ('localId' => $local, 'mdrId' => $mdr);
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
    return $entry->get ('Internal InstanceId');
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

=head1 ABSTRACT

The abstract that will go in the main Remedy::CMDB module will go here.

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
