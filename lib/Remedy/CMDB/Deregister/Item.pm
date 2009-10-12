package Remedy::CMDB::Deregister::Item;
our $VERSION = "0.50";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Deregister::Item - a single deregistartion in the CMDB

=head1 SYNOPSIS

    use Remedy::CMDB::Deregister::Item;

=head1 DESCRIPTION

Remedy::CMDB::Deregister::Item records information about a single entry in the
CMDB, and offers functionality to both search the database for that information
and to update the information when appropriate.

Remedy::CMDB::Deregister::Item is a sub-class of B<Remedy::CMDB::Struct>, and
inherits many functions from there.

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Item::InstanceID;
use Remedy::CMDB::Deregister::Response;

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
B<Remedy::CMDB::Item::InstanceID> object.

=cut

sub fields {
    'instanceId' => '$',    # generally Remedy::CMDB::Item::InstanceID
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

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    my $type = $xml->tag; 
    unless ($self->tag_type eq $type) {
        return "tag type is $type, should be " . $self->tag_type;
    }

    my $obj = Remedy::CMDB::Item::InstanceID->read ('xml',
        'source' => $xml, 'type' => 'object');
    return 'no object created' unless $obj;
    
    $self->instanceId ($obj);
    return "no instanceId" unless $self->instanceId;

    return;
}

=item tag_type 

I<item>

=cut

sub tag_type { 'instanceId' }

=back

=cut

##############################################################################
### Related Objects ##########################################################
##############################################################################

=head2 Related Objects

=over 4

=item response (ARGS)

Creates a B<Remedy::CDMB::Deregister::Response> object based on the argument
array I<ARGS>.

=cut

sub response { shift; Remedy::CMDB::Deregister::ResponseItem->new (@_) }

=item source_data ()

Same as B<instanceId>.

=cut

sub source_data { shift->instanceId; }

=back

=cut

##############################################################################
### Data Manipulation ########################################################
##############################################################################

=head2 Data Manipulation

=over 4

=item find (CMDB, ARGHASH)

Searches I<CMDB> for the current item.  What this really means: we find the
appropriate internal Instance ID by running the local mdrId and localId through
B<Remedy::CMDB::translate_instanceid ()>, and then search the remedy database
for that particular ID.

Arguments that we can take through I<ARGHASH>:

=over 4

=item class I<CLASS>

What class/table should we search?  Defaults to 'baseElement'.

=back

On success, returns all matching items (or, if requested in a scalar context,
only the first item).  On failure, returns undef.  Dies if the search went
badly in some way.

=cut

sub find {
    my ($self, $cmdb, %args) = @_;
    my $logger  = $cmdb->logger_or_die;

    my $mdrId   = $self->mdrId   or $logger->logdie ('no mdrId');
    my $localId = $self->localId or $logger->logdie ('no localid');

    ## What class are we going to be searching?
    my $class = $args{'class'} || 'baseElement';
    my $translate_class = $cmdb->translate_class ($class) ||
        $logger->logdie ("no translation of class '$class'");

    my $instanceid = eval { $cmdb->translate_instanceid ($mdrId, $localId, 
        %args) };
    if ($@) { 
        $logger->logdie ("failed to translate MDR info: $@\n") ;
    } elsif (!$instanceid) { 
        $logger->debug ("no match found in $translate_class");
        return;
    }

    my $string = "$instanceid in $translate_class";
    $logger->debug ("searching for $string");
    my @items = $cmdb->read ($translate_class, {'InstanceId' => $instanceid});
    if (scalar @items == 0) {
        $logger->logdie ("found in translation table, but no matching entry in $class\n");
    }

    return wantarray ? @items : $items[0];
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

The only possible change is to set 'MarkAsDeleted' to 1.  Is it already so
marked, or do we need to do it?

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

=item response B<Remedy::CMDB::Deregister::Response>

An object that contains information about all attempted registrations this run.

=back

On success, updates the B<Remedy::CMDB::Deregister::Response> object and 
returns undef.  On failure, returns a string explaining what went
wrong with the registration.

=cut

sub register {
    my ($self, $cmdb, %args) = @_;
    return 'no cmdb connection' unless $cmdb && $cmdb->remedy;
    my $logger  = $cmdb->logger_or_die ('no logger at item registration');

    ## Parse arguments from %args 
    my $response   = $args{'response'}   or return 'no response object offered';
    my $dataset    = $args{'dataset'}    or return 'no dataset offered';
    my $mdr_parent = $args{'mdr_parent'} or return 'no parent mdr offered';

    ## Make sure we have all the local object info we'll need to proceed.
    my $name     = $self->localId  or return 'no localId';
    my $mdrId    = $self->mdrId    or return 'no mdrId';
    my $datatype = 'baseElement';

    ## First real check: do the MDRs match? 
    return 'mdrId does not match parent mdrId' unless $mdrId eq $mdr_parent;

    ## Do we know how to deal with this particular class?
    my $class = $cmdb->translate_class ($datatype) 
        or return "invalid class: $datatype";

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
        return 'item does not exist';

    } elsif (scalar @obj > 1) { 
        return 'too many objects found';

    } else {
        $logger->debug ("found existing object '$name' in '$dataset'");
        $obj = $obj[0];
    }

    
    if (my $orig = $obj->get ('MarkAsDeleted')) { 
        # no changes to make
    } else {
        $obj->set ('MarkAsDeleted', 1);
        push @changes, "marking item as deleted";
    }

    ## What changes have we made?  Let's make it human-readable.
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
    $response->add_accepted ($self, $string, 'obj' => $obj) if $response;
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

=cut

sub id      { shift->instanceId->id }

=item localId ()

Returns B<localId ()> from B<instanceId ()>.

=cut

sub localId { shift->instanceId->localId }

=item mdrId ()

Returns B<mdrId ()> from B<instanceId ()>.

=cut

sub mdrId   { shift->instanceId->mdrId   }

=item name ()

Same as B<id ()>.

=cut

sub name { shift->id (@_) }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 NOTES

Make all of this stuff far, far more generic.

=head1 REQUIREMENTS

B<Remedy::CMDB::Item::InstanceID>,
B<Remedy::CMDB::Deregister::Response>,
B<Remedy::CMDB::Struct>

=head1 SEE ALSO

Remedy::CMDB::Relationship(8), Remedy::CMDB::Deregister(8)

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
