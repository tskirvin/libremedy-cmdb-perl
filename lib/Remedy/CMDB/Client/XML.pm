package Remedy::CMDB::Client::XML;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our %TYPES = (
    'queryRequest'     => 'Remedy::CMDB::Query',
    'registerRequest'  => 'Remedy::CMDB::Register',
);

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

# use Remedy::CMDB::Query;
use Remedy::CMDB::Register;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

=cut

sub fields {
    'environment' => '%',
    'class'       => '$',
    'query'       => '$',
}

=item populate_xml (XML)

Takes an XML::Twig::Elt object I<XML>

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'invalid tag type: ' . $xml->tag
        unless ($xml->tag eq $self->tag_type); 

    $self->clear_object;

    if (my $env = $xml->first_child ('environment')) {
        foreach my $child ($env->children) { 
            my $field = $child->tag;
            my $value = $child->child_text;
            $self->environment ($field, $value);
        }
    }

    my $found = 0;;
    foreach my $child ($xml->children ('request')) { 
        foreach my $request ($child->children) { 
            my $type = $request->tag;
            return "invalid type: $type" unless $TYPES{$type};
            return 'too many requests found' if $found++;
            $self->class ($TYPES{$type});
            
            my $objtype = $TYPES{$type};    
            my $obj = $objtype->read ('xml', 'source' => $request, 
                'type' => 'object');   
            return "no $objtype object created" unless $obj;
            $self->query ($obj);
        }
    }
    return "no valid query found" unless $self->query;
    return;
}

sub clear_object {
    my ($self) = @_;
    $self->environment (\{});
    $self->query ('');
    $self->type  ('');
    return;
}

sub tag_type { 'cmdb-client' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
