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

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=cut

sub id      { shift->instanceid->id }
sub localid { shift->instanceid->localid }
sub mdrid   { shift->instanceid->mdrid   }

sub fields {
    'instanceid' => 'Remedy::CMDB::Item::InstanceID',
    'record'     => '$',
}

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
        $self->instanceid ($id);
        return "no instanceid" unless $self->instanceid;
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

=item text ()

=cut

sub text {
    my ($self, %args) = @_;
    my @return;
    push @return, "ID: " . $self->instanceid->text;
    foreach my $record ($self->record) { 
        foreach ($record->text) { push @return, '  ' . $_; }
    }
    return wantarray ? @return : join ("\n", @return, '');
}

=item xml ()

=cut

sub xml {
    my ($self, %args) = @_;
}

=back

=cut

##############################################################################
### Stubs ####################################################################
##############################################################################

=head2 Stubs

These functions are stubs; the real work is implemented by the sub-functions.

=over 4

=item source

=item target

=back

=cut

sub source { "Not implemented" }
sub target { "Not implemented" }

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
