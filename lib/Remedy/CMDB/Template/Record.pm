package Remedy::CMDB::Template::Record;
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

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=cut

sub fields {
    'meta' => '%',
    'type' => '$',
    'hash' => '%',
}

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be record' unless (lc $xml->tag eq 'record'); 
    
    $self->clear_object;

    my $count;
    foreach my $child ($xml->children) {
        my $tag = $child->tag;
        if ($tag eq 'recordMetadata') { 
            foreach my $subchild ($child->children) {
                my $subtag = $subchild->tag;
                my $subval = $subchild->child_text;
                $self->meta ($subtag, $subval);
            }
        } else {
            return 'too many items in record' if $count++;
            $self->type ($tag);
            foreach my $subchild ($child->children) { 
                my $subtag = $subchild->tag;
                my $subval = $subchild->child_text;
                $self->hash ($subtag, $subval);
            }
        }
    }
    return 'no items in count' unless $count;

    return;
}

sub clear_object {
    my ($self) = @_;
    $self->meta ({});
    $self->hash ({});
    $self->type (undef);
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

    if (my $hash = $self->hash) { 
        push @return, "Data";
        foreach (keys %{$hash}) {
            push @return, "  $_: $$hash{$_}";
        }
    }

    my $meta = $self->meta;
    if (scalar keys %{$meta}) {
        push @return, "Metadata";
        foreach (keys %{$meta}) { 
            push @return, "  $_: $$meta{$_}";
        }
    } 
        
    return wantarray ? @return : join ("\n", @return, '');
}

=item xml ()

=cut

sub xml  {
    my ($self) = @_;
    return 'not done yet';
}

=back

=cut

##############################################################################
### Stubs ####################################################################
##############################################################################

=head2 Stubs

These functions are stubs; the real work is implemented by the sub-functions.

=over 4

=item tag_type 

=back

=cut

sub tag_type { "not implemented" } 

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
