package Remedy::CMDB::XML;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB;
use XML::Twig;

##############################################################################
### Functions ################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item new (SOURCE [, ARGHASH]) 

=cut

sub new  { 
    my ($class, $source, %opts) = @_;
    my $self = {};  bless $self, $class;  
    my $xml = new XML::Twig;

    my $type = $opts{'type'} || "";
    (lc $type eq 'stream' ? $xml->safe_parse     ($source)
                          : $xml->safe_parsefile ($source)) or return undef;

    $$self{'DATA'}  = $xml->root;
    $$self{'ERROR'} = undef;
    return $self;
}

sub mdrId { shift->_firstitem ('mdrId') }

# record, instanceId
sub items {}

# source, target, record
sub relationships {}


##############################################################################
### Internal Subroutines #####################################################
##############################################################################

sub _cleantext {
    my ($text, %options) = @_;
    return "" if $text =~ /^\s*$/;
    my @return = split ("\n", $text);

    # Clear end-line whitespace
    map { s/\s*$//g } @return;      

    # Clear leading and trailing newlines
    while ($return[0] =~ /^\s*$/)       { shift @return }
    while ($return[$#return] =~/^\s*$/) { pop @return   }

    return wantarray ? @return : join ("\n", @return);
}

##############################################################################
### Final Documentation ######################################################
##############################################################################
