package Remedy::CMDB::XML;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::XML - 

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

use Class::Struct;
use Exporter;
use XML::Twig;

our @EXPORT    = qw//;
our @EXPORT_OK = qw/init_struct/;
our @ISA       = qw/Exporter/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item init_struct (CLASS, ARGHASH)

=cut

sub init_struct {
    my ($class, %extra) = @_;
    our $new = $class . "::Struct";
    
    my %fields = $class->fields;
    struct $new => {
        'type'      => '$',
        'error'     => '$',
        'source'    => '$',
        %fields
    };

    return (__PACKAGE__, $new);
}

## intentionally left blank
sub fields {}

=item read (TYPE [, ARGHASH])

=cut

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


