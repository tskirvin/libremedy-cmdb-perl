package Remedy::CMDB::Relationship::XML;

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;

class __PACKAGE__ => {
    'data'  => '$',
    'error' => '$',
};

##############################################################################
### Methods ##################################################################
##############################################################################

sub new {
    my ($class, $source, %opts) = @_;
    my $self = {};
    bless $self, $class;

    my $xml = XML::Twig->new;
    
    my $type = $opts{'type'} || '';
    if (lc $type eq 'stream') { $xml->safe_parse ($source)     || return } 
    else                      { $xml->safe_parsefile ($source) || return }

    $self->data ($xml->root);
    $self->error ();
    return $self;
}

sub source {}
sub target {}
sub record {}

1;
