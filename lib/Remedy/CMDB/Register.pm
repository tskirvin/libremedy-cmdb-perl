package Remedy::CMDB::Register;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

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

use Remedy::CMDB::XML;

use Remedy::CMDB::Item;
use Remedy::CMDB::Relationship;

our @ISA = qw/Remedy::CMDB::XML/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item read (FILE)

=cut

sub read {
    my ($self, $file, %opts) = @_;
    
    my $xml = XML::Twig->new ();
    unless ($xml->safe_parsefile ($file)) { 
        die "couldn't parse '$file': $@\n";
    }
    my $root = $xml->root;

    $$self{'DATA'} = $root;

    return $self;
}

sub mdrid {
    my ($self) = @_;
    my $data = $self->data || return;
    return $data->att ('mdrId') || undef;
}

sub items         { 
    my ($self) = @_;
    return $self->_getdata ('itemList', 'item', 'Remedy::CMDB::Item');
}
sub relationships { 
    my ($self) = @_;
    $self->_getdata ('relationshipList', 'relationship',
        'Remedy::CMDB::Relationship');
}

sub text {
    my ($self) = @_;
    my @return;

    push @return, "ID: " . $self->mdrid;
    push @return, '', "Items";
    foreach ($self->items)         { push @return, '', $_->text }
    push @return, '', "Relationships";
    foreach ($self->relationships) { push @return, '', $_->text }

    wantarray ? @return : join ("\n", @return, '');
}

sub id {
    my ($self) = @_;
    my $mdrid = $self->mdrid || return;
    # 
    # return $mdrid;
}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

sub _getatt { }

sub _getdata {
    warn "_gd: @_\n";
    my ($self, $listname, $objname, $class) = @_;
    return unless my $data = $self->data;
    return unless my $item = $data->first_child ($listname);

    return $item unless $objname;
    my @children = $item->children ($objname);
    return unless scalar @children;

    my @items;
    foreach my $i (@children) {
        $i->print;
        push @items, $class ? $class->new ('type' => 'xml')
                            : $i;
    }
    return @items;
}


##############################################################################
### Final Documentation ######################################################
##############################################################################

1;


