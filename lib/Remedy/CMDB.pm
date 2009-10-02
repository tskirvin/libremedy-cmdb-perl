package Remedy::CMDB;
our $VERSION = "0.50.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB - an OO interface to the Remedy CMDB

=head1 SYNOPSIS

    use Remedy::CMDB;

    my $config = eval { Remedy::CMDB::Confiog->load () };
    die "could not load CMDB config: $@" unless $config;

    my $cmdb = eval { Remedy::CMDB->connect ('config' => $config') };
    die "could not connect to CMDB: $@" unless $cmdb;

TODO: add more things you can then do with the CMDB here

=head1 DESCRIPTION

Remedy::CMDB offers a generic object-oriented interface to BMC's CMDB
(Configuration Management DataBase), run through its Remedy package.  This
primarily consists of a B<Remedy> object, but has a fair number of additional
functionality built in to support object registration and queries.

Remedy::CMDB is implemented as a B<Class::Struct> object.

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

=head1 FUNCTIONS

=head2 B<Class::Struct> Subroutines 

=over 4

=item config B<Remedy::CMDB::Config>

Configuration information is stored in this object.

=item logobj B<Remedy::CMDB::Log>

The logging is handled through this object.

=item remedy B<Remedy>

The interface back to the Remedy CMDB is managed through this object.

=back

=cut

##############################################################################
### Object Contstruction #####################################################
##############################################################################

=head2 Construction

=over 4

=item connect (ARGHASH)

Creates the B<Remedy::CMDB> object and connects to the underlying B<Remedy>
object to the Remedy server.  I<ARGHASH> is an array of key/value pairs used to
modify default behavior; valid values are:

=over 4

=item config (I<Remedy::CMDB::Config> or I<FILE>)

Uses the configuration file I<FILE> or the pre-loaded configuration
I<Remedy::CMDB::Config> for local configuration.  If not offered, then we'll
load the defaults.

=item debug (I<COUNT>)

For every level of integer I<COUNT>, increases the debugging level by one
(using B<Remedy::Log::more_logging ()>).  

=back

Returns the new B<Remedy::CMDB> object on success, or dies on failure.

=cut

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

    ## From now on, we can print debugging messages when necessary
    my $logger = $self->logger_or_die ('no logger at init');

    my $remedy = eval { Remedy->connect ('config' => $conf->remedy_config, 
        'debug' => $args{'debug'}) };
    $logger->logdie ("couldn't connect to database: $@") unless $remedy;
    $logger->logdie ($@) if $@;

    $self->remedy ($remedy);
    $remedy->logobj ($self->logobj);        

    return $self;
}

=back

=cut

##############################################################################
### Item Routines ############################################################
##############################################################################

=head2 Item Routines 

Items, also known as Configuration Items (CIs), are the primary items stored in
the CMDB.  These items are primarily handled through the B<Remedy::CMDB::Item>
package; these functions are primarily helper functions to access them
conveniently.

=over 4

=item find_item (OBJECT, ARGHASH)

Searches for a B<Remedy::CMDB::Item> object in the CMDB.  Creates a new
B<Remedy::CMDB:Item> object based on I<OBJECT> (any object that contains the
functions C<mdrId ()> and C<localId ()>), and runs it through its B<find ()>
function.  I<ARGHASH> is offered to the B<find ()> as additional arguments.

=cut

sub find_item {
    my ($self, $obj, @rest) = @_;
    my $item = Remedy::CMDB::Item->new ('instanceId' => $obj);
    return $item->find ($self, @rest);
}

=item register_item (ITEM, ARGUMENTS)

Invokes B<register (ARGUMENTS)> on I<ITEM>.

=cut

sub register_item {
    my ($self, $item, @rest) = @_;
    return $item->register ($self, @rest);
}

=back

=cut

##############################################################################
### Relationship Routines ####################################################
##############################################################################

=head2 Relationship Routines 

Relationships are a special class of Item/CI, linking two other CIs.  They are
managed through B<Remedy::CMDB::Relationship>.

=over 4

=item find_relationship (SOURCE, TARGET, ARGHASH)

Searches for a B<Remedy::CMDB::Relationship> object in the CMDB.  Creates a
new B<Remedy::CMDB:Relationship> object basid on I<OBJECT> (any object that
contains the functions C<source ()> and C<target ()>), and runs it through its
B<find ()> function.  I<ARGHASH> is offered to the B<find ()> as additional
arguments.

=cut

sub find_relationship {
    my ($self, $source, $target, @rest) = @_;
    my $relationship = Remedy::CMDB::Relationship->new ('source' => $source, 
        'target' => $target);
    return $relationship->find ($self, @rest);
}

=item register_relationship (RELATIONSHIP, ARGHASH)

Invokes B<register (ARGUMENTS)> on I<RELATIONSHIP>.

=cut

sub register_relationship {
    my ($self, $relationship, @rest) = @_;
    return $relationship->register ($self, @rest);
}

=back

=cut

##############################################################################
### Translation Routines #####################################################
##############################################################################

=head2 Translation Routines 

Stanford's major extension to the main CMDB is a global translation table,
which maps Dataset and local IDs of items and relationships into the actual
internal Instance IDs used within each table of the CMDB itself.  While most of
the work within this table is handled through internal workflow, these
functions handle the rest.

=over 4

=item find_translation (STUB [, CLASS])

=cut

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

=item register_translation (FIELDS)

Registers the current 

=cut

sub register_translation {
    my ($self, %args) = @_;
    my $logger  = $self->logger_or_die ('no logger at item registration');
    my $remedy  = $self->remedy_or_die ('no remedy at item registration');
    my $session = $remedy->session_or_die ('no remedy session');

    my $instanceId = $args{'instanceId'} || return 'no instanceId';
    my $datasetId  = $args{'datasetId'}  || return 'no datasetId';

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

=item translate_instanceid (MDRID, LOCALID)

Finds the internal Instance ID used within the CMDB, based on the offered
MDR I<MDRID> and Local ID I<LOCALID>.  If more than one match is found, then we
die; otherwise, we return the I<Internal InstanceId> field from the data if we
find it, or undef if nothing is found.

=cut

sub translate_instanceid {
    my ($self, $mdr, $local) = @_;
    my $logger = $self->logger_or_die ('no logger at item registration');

    $logger->debug ("translate_instanceid ($mdr, $local)");

    my $class = $self->translate_class ('translate') or return;

    my %search = ('localId' => $local, 'mdrId' => $mdr);
    my $string = "translation of $local\@$mdr";

    $logger->debug ("searching for $string");
    my @translate = $self->read ($class, \%search);
    if (scalar @translate == 0) {
        $logger->debug ("no matches for $string");
        return;
    } elsif (scalar @translate > 1) {
        $logger->logdie (sprintf ("too many matches (%d) for %s\n", 
            scalar @translate, $string));
    } 

    my $entry = $translate[0];
    return $entry->get ('Internal InstanceId');
}

=back

=cut

##############################################################################
### Miscellaneous Subroutines ################################################
##############################################################################

=head2 Miscellaneous Subroutines 

=over 4

=item create (ARGS)

Runs B<create ()> through the B<remedy ()> object.

=cut

sub create { shift->remedy_or_die->create (@_) }

=item logger (ARGS)

Returns the actual B<Log::Log4perl> object to which we can write log messages.

=cut

sub logger { shift->logobj_or_die->logger (@_) }

=item read (ARGS)

Runs B<read ()> through the B<remedy ()> object.

=cut

sub read   { shift->remedy_or_die->read (@_) }

=item translate_class

Converts a human-readable class name to the remedy table that it should be
stored in.  Uses B<class_human_to_remedy> from B<Remedy::CMDB::Config>.

=cut

sub translate_class { shift->config_or_die->class_human_to_remedy (@_) }

=item config_or_die

=item logobj_or_die

=item logger_or_die

=item remedy_or_die

Returns the appropriate item type, or dies.

=cut

sub config_or_die { shift->_or_die ('config', "no configuration", @_) }
sub logobj_or_die { shift->_or_die ('logobj', "no logger",        @_) }
sub logger_or_die { shift->_or_die ('logger', "no logger",        @_) }
sub remedy_or_die { shift->_or_die ('remedy', "no remedy",        @_) }

=back

=cut

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

Remedy::CMDB offers a generic object-oriented interface to BMC's CMDB
(Configuration Management DataBase), run through its Remedy package.  This
primarily consists of a B<Remedy> object, but has a fair number of additional
functionality built in to support object registration and queries.

=head1 NOTES

This document is not intended as an introduction to the concept of a CMDB.  

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
