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

use Remedy::CMDB::Item;
use Remedy::CMDB::Relationship::Record;
use Remedy::CMDB::Relationship::Source;
use Remedy::CMDB::Relationship::Target;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = (init_struct (__PACKAGE__), 'Remedy::CMDB::Item');

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=cut

sub fields {
    'record' => 'Remedy::CMDB::Relationship::Record',
    'source' => 'Remedy::CMDB::Relationship::Source',
    'target' => 'Remedy::CMDB::Relationship::Target',
}

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

=item text ()

=cut

sub tag_type { 'relationship' }

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
