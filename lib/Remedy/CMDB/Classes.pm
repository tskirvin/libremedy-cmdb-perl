package Remedy::CMDB::Classes;
our $VERSION = "0.50";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Classes - map Remedy CI types and human class names

=head1 SYNOPSIS

    use Remedy::CMDB::Classes;

    my $classes = Remedy::CMDB::Sources->read ($file);

    my $class = $classes->human_to_remedy ($human);
    my $human = $classes->remedy_to_human ($remedy);

=head1 DESCRIPTION

Remedy::CMDB::Classes is used to parse a CMDB configuration file that maps
Remedy CI types to human-readable versions of the same (the ones that are used
in the public XML).

=head1 DATA FILE FORMAT

The file is a comma-separate file, with lines like this:

    CI_TYPE, HUMAN, HUMAN, [...]

=cut


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
### Methods ##################################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item human_to_remedy (HUMAN)

Converts the human-supplied name I<HUMAN> to the proper Remedy CI name.

=cut

sub human_to_remedy {
    my ($self, $human) = @_;
    return unless my $obj = $self->human ($human);
    return $obj->remedy;
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

=item remedy_to_human (REMEDY)

Converts the human-supplied name I<HUMAN> to the proper Remedy CI name.

=cut

sub remedy_to_human {
    my ($self, $remedy) = @_;
    return unless my $obj = $self->remedy ($remedy);
    return $obj->human;
}

=item validate (HUMAN)

Return 1 if I<HUMAN> maps to a valid Remedy CI name; otherwise, return undef.

=cut

sub validate {
    my ($self, $human) = @_;
    return 1 if $self->human_to_remedy ($human);
    return;
}

=item valid_names (REMEDY)

Return an array of valid names for the remedy CI named I<REMEDY>.

=cut

sub valid_names {
    my ($self, $remedy) = @_;
    my @human = $self->remedy_to_human ($remedy);
    return () unless scalar @human;
    return @human;
}

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 TODO

Doing this by some means other than CSV would probably be nice.  Also, we're
probably going to get rid of most of this, and do it by just straight-up
converting the names programmatically.  It'll be nicer.

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
