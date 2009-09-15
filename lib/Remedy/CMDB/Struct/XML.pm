package Remedy::CMDB::Struct::XML;
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

use Remedy::CMDB::Struct;

our @ISA = qw/Remedy::CMDB::Struct/;

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item load (SOURCE, ARGHASH)

=cut

sub load_xml_bad {
    my ($self, %opts) = @_;
    my $class = ref $self ? ref $self : $self;

    my $xml;
    my $type   = $opts{'type'}   || return "no valid type";
    my $source = $opts{'source'} || return "no valid source";
    if      (lc $type eq 'stream') {
        $xml = XML::Twig->new ('no_prolog' => 1);
        return "could not parse: $@" unless $xml->safe_parse ($source);
    } elsif (lc $type eq 'file') {
        $xml = XML::Twig->new ('no_prolog' => 1);
        return "could not parse: $@" unless $xml->safe_parsefile ($source);
    } elsif (lc $type eq 'object') {
        $xml = $source;
    } else {
        return "invalid type: '$type'";
    }

    my $new = $class->new ();
    $new->data ($xml);
    $new->type ('xml');
    $new->populate ();
    
    return $new;
}

=item populate ()

(Intentionally left blank.)

=cut

sub populate { }

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


