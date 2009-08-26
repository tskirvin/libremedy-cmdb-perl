package Remedy::CMDB::Classes;

##############################################################################
### Declarations #############################################################
##############################################################################

use Class::Struct;
use Text::CSV;

use strict;

struct 'Remedy::CMDB::Classes' => { 'human' => '%', 'remedy' => '%' };
struct 'Remedy::CMDB::Classes::Class' => {
    'remedy' => '$',
    'human'  => '@',
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
        my ($remedy, @human) = $csv->fields ();
        next unless $remedy;
        map { s/^\s+|\s+$//g } @human;
        push @human, $remedy;
        my $obj = Remedy::CMDB::Classes::Class->new (
            'remedy'    => $remedy,
            'human'     => \@human,
        );
        $self->remedy ($remedy, $obj);
        foreach (@human) { 
            if (my $exists = $self->human ($_)) {
                die "$_ already exists as '$exists'";
            };
            $self->human ($_, $obj) 
        }
    }
    close FILE;

    return $self;
}

sub human_to_remedy {
    my ($self, $human) = @_;
    return unless my $obj = $self->human ($human);
    return $obj->remedy;
}

sub remedy_to_human {
    my ($self, $remedy) = @_;
    return unless my $obj = $self->remedy ($remedy);
    return $obj->human;
}

sub validate {
    my ($self, $human) = @_;
    return 1 if $self->human_to_remedy ($human);
    return
}

sub valid_names {
    my ($self, $remedy) = @_;
    my @human = $self->remedy_to_human ($remedy);
    return () unless scalar @human;
    return @human;
}

1;
