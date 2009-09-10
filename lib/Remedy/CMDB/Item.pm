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

=over 4

=cut

sub id      { shift->instanceId->id }
sub localId { shift->instanceId->localId }
sub mdrId   { shift->instanceId->mdrId   }

sub fields {
    'instanceId' => 'Remedy::CMDB::Item::InstanceID',
    'record'     => '$',
}

sub source_data {
    my ($self) = @_;
    my $src = Remedy::CMDB::Item::DataSource->new ('instanceId' => 
        $self->instanceId);
    return $src;
}

sub response { shift; Remedy::CMDB::Item::Response->new (@_) }

sub datatype { shift->record->datatype }

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

=item text ()

=cut

sub tag_type { 'item' }

sub text_old {
    my ($self, %args) = @_;
    my @return;
    push @return, "ID: " . $self->instanceId->text;
    foreach my $record ($self->record) { 
        foreach ($record->text) { push @return, $_; }
        push @return, '';
    }
    return wantarray ? @return : join ("\n", @return, '');
}

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
