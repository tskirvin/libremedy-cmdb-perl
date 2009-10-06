package Remedy::CMDB::Template::Response::Global;
our $VERSION = "0.01";

=head1 NAME

Remedy::CMDB::Template::Response::Global - global response template

=head1 SYNOPSIS

    use Remedy::CMDB::Template::Response::Global;

=head1 DESCRIPTION

Remedy::CMDB::Template::Response::Global offers a method for a 'global'
response to an error, where we don't yet know what particular sub-class we want
to use.  It is used by B<Remedy::CMDB::Template::Response>.

Remedy::CMDB::Item is a sub-class of B<Remedy::CMDB::Struct>, and inherits
many functions from there.


=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Template::Response::Global::DataSource;
use Remedy::CMDB::Template::Response::Global::Response;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Class::Struct Accessors ##################################################
##############################################################################

=head1 FUNCTIONS

=head2 B<Class::Struct Accessors>

=over 4

=item text ($)

The text of the error.

=cut

sub fields { 'text' => '$' }

=back

=cut

##############################################################################
### Remedy::CMDB::Struct Overrides ###########################################
##############################################################################

=head2 B<Remedy::CMDB::Struct> Overrides

These functions are documented in more detail in the B<Remedy::CMDB::Struct>
class.  Sub-classes of the template will probably want to override those
functions labelled 'stub'.

=over 4

=item fields ()

=item populate_xml ()

Not populated.

=cut

sub populate_xml { return 'not yet implemented' }

=item tag_type 

I<global>

=cut

sub tag_type { 'global' }

=back

=cut

##############################################################################
### Additional Functions #####################################################
##############################################################################

=head2 Additional Functions 

=over 4

=item source_data ()

Creates a B<Remedy::CMDB::Template::Response::Global::DataSource> object with
the value of the local B<text ()>, and returns it.

=cut

sub source_data {
    my ($self) = @_;
    my $src = Remedy::CMDB::Template::Response::Global::DataSource->new (
        'text' => $self->text);
    return $src;
}

=item response ()

Returns a new B<Remedy::CMDB::Template::Response::Global::Response> object.

=cut

sub response {
    my ($self, @args) = @_;
    Remedy::CMDB::Template::Response::Global::Response->new (@args);
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 NOTES

This was generated back when I was planning on using the same kinds of
redirection tricks for Item and Relationship as well.  It may well be easier to
do this some other way, but it's hard to argue with this since it should work.

=head1 REQUIREMENTS

B<Remedy::CMDB::Struct>,
B<Remedy::CMDB::Template::Response::Global::DataSource>,
B<Remedy::CMDB::Template::Response::Global::Response>

=head1 SEE ALSO

B<Remedy::CMDB::Template::Response>

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
