package Remedy::CMDB::Config;
our $VERSION = '0.55';

=head1 NAME

Remedy::CMDB::Config - Remedy configuration files and logging

=head1 SYNOPSIS

    use Remedy::CMDB::Config;

    my $file = '/etc/remedy/remedy.conf';
    my $config = Remedy::CMDB::Config->load ($file);

=head1 DESCRIPTION

Remedy::CMDB::Config encapsulates the configuration information specific to
B<Remedy::CMDB>.  It is implemented as a Perl class that declares and sets
the defaults for various configuration variables and then loads (in order of
preference) the offered filename, the one specified by the REMEDY_CMDB_CONFIG
environment variable, or F</etc/remedy/cmdb_config>.  That file should contain
any site-specific overrides to the defaults, and at least some parameters must
be set.

This file must be valid Perl.  To set a variable, use the syntax:

    $VARIABLE = <value>;

where VARIABLE is the variable name (always in all-capital letters) and <value>
is the value.  If setting a variable to a string and not a number, you should
normally enclose <value> in C<''>.  For example, to set the variable PORT to
C<111>, use:

    $PORT= '111';

Always remember the initial dollar sign (C<$>) and ending semicolon (C<;>).
Those familiar with Perl syntax can of course use the full range of Perl
expressions.

This configuration file should end with the line:

    1;

This ensures that Perl doesn't think there is an error when loading the file.

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our %FUNCTIONS;

=head1 Configuration

All of the configuration options below have a related B<Class::Struct> accessor
(of type '$' unless noted).

=over 4

=item $PORT

Port to listen to for the cmdb daemon Matches the B<port) accessor            .

=cut

our $PORT = "5048";
$FUNCTIONS{'port'} = \$PORT;

=item $CONFIG

The location of the configuration file we're going to load to get defaults.
Defaults to F</etc/remedy/cmdb_config>; can be overridden either by passing
a different file name to B<load ()>, or by setting the environment variable
I<REMEDY_CMDB_CONFIG>.

Matches the B<config> accessor.

=cut

our $CONFIG = '/etc/remedy/cmdb_config';
$FUNCTIONS{'config'} = \$CONFIG;

=back

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;

my %opts;
foreach (keys %FUNCTIONS) { $opts{$_} = '$' }

struct 'Remedy::CMDB::Config' => { 
    %opts, 
};

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 Subroutines

=head2 B<Class::Struct> Accessors

The accessors listed in CONFIGURATION can be initialized via B<new ()> or
per-function.

=over 4

=item config ($)

=item port ($)

=back

=head2 Additional Functions

=over 4

=item load ([FILE])

Creates a new B<Remedy::CMDB::Config> object, loads F<FILE> to update defaults,
(if not offered, the value of the environment variable I<REMEDY_CMDB_CONFIG> or
the value of I<$CONFIG>), and initalizes the object from the defaults.  This
includes creating the B<Remedy::Log> object.

Returns the new object.

=cut

sub load {
    my ($class, $file) = @_;
    $file ||= $ENV{'REMEDY_CMDB_CONFIG'} || $CONFIG;
    do $file or LOGDIE ("Couldn't load '$file': " . ($@ || $!) . "\n");
    my $self = $class->new ();

    $self->config ($file);
    _init_functions ($self);

    return $self;
}

=item debug ()

Return a string with all valid keys and values listed.

=cut

sub debug {
    my ($self) = @_;
    my @return;
    foreach my $key (keys %FUNCTIONS) { 
        my $value = $self->$key;
        push @return, sprintf ("%s: %s", $key, defined $value ? $value 
                                                              : '*undef*');
    }
    wantarray ? @return : join ("\n", @return, '');
}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

### _init_functions ()
# Takes care of setting the various options.  
sub _init_functions {
    my ($self) = @_;
    foreach my $key (keys %FUNCTIONS) { 
        my $value = $FUNCTIONS{$key};
        $self->$key ($$value) 
    }
    $self;
}

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 ENVIRONMENT

=over 4

=item REMEDY_CMDB_CONFIG

If this environment variable is set, it is taken to be the path to the remedy
configuration file to load instead of F</etc/remedy/cmdb_config>.

=back

=cut

=head1 REQUIREMENTS

B<Remedy::Log>

=head1 SEE ALSO

Class::Struct(8), Remedy(8)

=head1 HOMEPAGE

TBD.

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2008-2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
