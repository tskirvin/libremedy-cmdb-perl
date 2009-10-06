package Remedy::CMDB::Sources;
our $VERSION = "0.50";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Sources - map MDRs to datasources and authorized principals

=head1 SYNOPSIS

    use Remedy::CMDB::Sources;

    my $sources = Remedy::CMDB::Sources->read ($file);

    my $dataset    = $sources->mdr_to_src ($mdr)
    my $mdr        = $sources->src_to_mdr ($datasrc);
    my @principals = $sources->mdr_to_princ ($mdr);

=head1 DESCRIPTION

Remedy::CMDB::Sources is used to parse a CMDB configuration file that maps MDRs
(Master Data Records) to the relevant Data Source and kerberos principals that
are allowed to write to it.

=head1 DATA FILE FORMAT

The file is a comma-separate file, with lines like this:

    MDR, DATASOURCE, PRINCIPAL, PRINCIPAL, PRINCIPAL, [...]

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Class::Struct;
use Text::CSV;

struct 'Remedy::CMDB::Sources' => { 'mdr' => '%', 'src' => '%' };
struct 'Remedy::CMDB::Sources::Source' => {
    'mdr'        => '$',
    'datasource' => '$',
    'principal'  => '@',
};

##############################################################################
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item datasource (MDR)

Same as B<mdr_to_src>.

=cut

sub datasource { shift->mdr_to_src (@_) }

=item mdr_to_princ (MDR)

Return a list of kerberos principals allowed to write to MDR I<MDR>.

=cut

sub mdr_to_princ {
    my ($self, $mdr) = @_;
    return unless my $obj = $self->mdr ($mdr);
    return @{$obj->principal};
}

=item mdr_to_src (MDR)

Return the datasource associated with MDR I<MDR>.

=cut

sub mdr_to_src {
    my ($self, $mdr) = @_;
    return unless my $obj = $self->mdr ($mdr);
    return $obj->datasource;
}

=item read (FILE)

Parse I<FILE> to populate the object.

=cut

sub read {
    my ($class, $file) = @_;
    my $self = $class->new;

    my $csv = Text::CSV->new ({'allow_whitespace' => 1});
    open (FILE, $file) or die "could not open $file: $@";
    while (<FILE>) {
        chomp;
        s/\#.*$//;
        next if /^\s*$/;
        my $status = $csv->parse ($_) || next;
        my ($mdr, $datasource, @princ) = $csv->fields ();
        next unless ($mdr && $datasource);
        my $obj = Remedy::CMDB::Sources::Source->new (
            'mdr'        => $mdr,
            'datasource' => $datasource,
            'principal'  => \@princ,
        );
        $self->src ($datasource, $obj);
        $self->mdr ($mdr, $obj);
    }
    close FILE;

    return $self;
}

=item src_to_mdr (SRC)

Return the MDR associated with datasource I<SRC>

=cut

sub src_to_mdr {
    my ($self, $src) = @_;
    return unless my $obj = $self->src ($src);
    return $obj->mdr;
}

=item validate_principal (MDR, PRINCIPAL)

Looks at the principals allowed to write to I<MDR>, and if I<PRINCIPAL> matches
then we'll return it.  Otherwise, return undef (indicating that we're not
allowed to write).

=cut

sub validate_principal {
    my ($self, $mdr, $principal) = @_;
    my @valid = $self->mdr_to_princ ($mdr);
    foreach (@valid) { return $principal if $principal eq $_ }
    return;
}

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 TODO

Doing this by some means other than CSV would probably be nice.

=head1 REQUIREMENTS

B<Text::CSV>

=head1 SEE ALSO

B<Remedy::CMDB::Config>

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
