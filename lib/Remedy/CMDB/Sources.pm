package Remedy::CMDB::Sources;

##############################################################################
### Declarations #############################################################
##############################################################################

use Class::Struct;
use Text::CSV;

use strict;

struct 'Remedy::CMDB::Sources' => { 'mdr' => '%', 'src' => '%' };
struct 'Remedy::CMDB::Sources::Source' => {
    'mdr'        => '$',
    'datasource' => '$',
    'principal'  => '@',
};

##############################################################################
### main () ##################################################################
##############################################################################

=item read (FILE)

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

sub mdr_to_princ { 
    my ($self, $mdr) = @_;
    return unless my $obj = $self->mdr ($mdr);
    return @{$obj->principal};
}

sub mdr_to_src { 
    my ($self, $mdr) = @_;
    return unless my $obj = $self->mdr ($mdr);
    return $obj->datasource;
}

sub src_to_mdr { 
    my ($self, $src) = @_;
    return unless my $obj = $self->src ($src);
    return $obj->mdr;
}

sub datasource { shift->mdr_to_src (@_) }

sub validate_principal {
    my ($self, $mdr, $principal) = @_;
    my @valid = $self->mdr_to_princ ($mdr);
    foreach (@valid) { return $principal if $principal eq $_ }
    return;
}


1;
