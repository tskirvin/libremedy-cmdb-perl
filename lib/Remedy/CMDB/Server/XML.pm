package Remedy::CMDB::Server::XML;
our $VERSION = "0.50.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Server::XML - parse client XML and run commands based on it

=head1 SYNOPSIS

    use Remedy::CMDB::Server::XML;

=head1 DESCRIPTION

Remedy::CMDB::Server::XML parses the XML provided by B<Remedy::CMDB::Client>,
and converts it to a set of environment variables and a query type.  This XML
generally looks like this:

    <cmdb-client>
        <environment>
            <HOME>/home/tskirvin</HOME>
            <KRB5CCNAME>[...]</KRB5CCNAME>
            [...]
        </environment>
        <request>
            <registerRequest>
                [...]
            </registerRequest>
        </request>
    </cmdb-client>

Remedy::CMDB::Item is a sub-class of B<Remedy::CMDB::Struct>, and inherits
many functions from there.

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

=head1 VARIABLES

=over 4

=item %TYPES

=over 2

=item deregisterRequest

Maps to B<Remedy::CMDB::Deregister>

=item queryRequest

Maps to B<Remedy::CMDB::Query>

=item registerRequest

Maps to B<Remedy::CMDB::Register>

=back

=cut

our %TYPES = (
    'queryRequest'       => 'Remedy::CMDB::Query',
    'registerRequest'    => 'Remedy::CMDB::Register',
    'deregisterRequest'  => 'Remedy::CMDB::Deregister',
);

=back

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Deregister;
use Remedy::CMDB::Query;
use Remedy::CMDB::Register;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item environment (%)

Contains key/value pairs of everything set in the environment block of the XML.

=item class ($)

The associated class with this query type (see above).

=item query ($)

The actual query, generally as an object of class B<class ()>.

=cut

sub fields {
    'environment' => '%',
    'class'       => '$',
    'query'       => '$',
}

=back

=cut

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.

=over 4

=item fields ()

=item clear_object ()

=cut

sub clear_object {
    my ($self) = @_;
    $self->environment (\{});
    $self->class ('');
    $self->query ('');
    return;
}

=item populate_xml (XML)

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

=item tag_type ()

I<cmdb-client>

=cut

sub tag_type { 'cmdb-client' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Deregister>,
B<Remedy::CMDB::Query>, B<Remedy::CMDB::Register>, B<Remedy::CMDB::Struct>

=head1 HOMEPAGE

TBD.

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
