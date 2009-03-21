package Remedy::CMDB::XML;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $DEBUG = 0;      

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use XML::Twig;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item new (FILE)

=cut

sub new {
    my ($class, $xml) = @_;
    my $self = {};
    bless $self, $class;

    $self->
    $self->read (@rest);

    return $self;
}

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

sub data { shift->{'DATA'} }

sub mdrid {
    my ($self) = @_;
    my $data = $self->data || return;
    return $data->att ('mdrId') || undef;
}

sub items         { 
    my ($self) = @_;
    return $self->_getdata ('itemList', 'item', 'Remedy::CMDB::XML::Item');
}
sub relationships { 
    my ($self) = @_;
    $self->_getdata ('relationshipList', 'relationship',
        'Remedy::CMDB::XML::Relationship');
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
        push @items, $class ? $class->new ($i)
                            : $i;
    }
    return @items;
}


##############################################################################
### Final Documentation ######################################################
##############################################################################

1;


