package Remedy::CMDB::Struct;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Struct - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $DEBUG = 0;      

our $LOGGER = Remedy::Log->get_logger ();

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use Exporter;
use XML::Twig;
use XML::Writer;
use Remedy::Log;

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
    $LOGGER->all ("initializing structure for '$class'");
    our $new = $class . "::Struct";
    
    my %fields = $class->fields;
    struct $new => {
        'type'      => '$',
        'error'     => '$',
        'data'      => '$',
        %fields
    };

    return (__PACKAGE__, $new);
}

## intentionally left blank
sub fields { () }

=item read (SOURCE, ARGHASH)

=cut

sub read {
    my ($self, $source, %opts) = @_;
    $self = $self->new unless (ref $self);

    my $obj;
    if    (lc $source eq 'xml')    { $obj = $self->read_xml    (%opts)  } 
    elsif (lc $source eq 'remedy') { $obj = $self->read_remedy (%opts)  }
    else                           { return "invalid source: '$source'" }

    if (! ref $obj) { 
        my $error = $obj || "unknown error";
        die "$error\n";
    } 
    return $obj;
}

=item read_xml (ARGHASH)

=over 4

=item source

=item type

=back

=cut

sub read_xml {
    my ($self, %opts) = @_;
    my $class = ref $self;
    
    my $type   = $opts{'type'}   || return "no valid type";
    my $source = $opts{'source'} || return "no valid source";

    my ($xml, $data);
    if      (lc $type eq 'stream') {
        my $xml = XML::Twig->new ();
        return "could not parse: $@" unless $xml->safe_parse ($source);
        $data = $xml->root;
    } elsif (lc $type eq 'file') {
        my $xml = XML::Twig->new ();
        return "could not parse: $@" unless $xml->safe_parsefile ($source);
        $data = $xml->root;
    } elsif (lc $type eq 'object') {
        $data = $source;
    } else {
        return "invalid type: '$type'";
    }

    if (my $error = $self->populate_xml ($data)) { 
        $LOGGER->error ("$class: couldn't populate from XML: $error");   
        return;
    }

    $self->type ('xml');
    $self->data ($data);
    $LOGGER->info ('created type ' . $data->tag);
    
    return $self;
}

sub read_remedy { }

sub populate_remedy { "not configured" }
sub populate_xml    { "not configured" }

## subroutines we'll want later, if just to override
sub text    {}
sub xml     {}
sub db_save {}
sub db_load {}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
