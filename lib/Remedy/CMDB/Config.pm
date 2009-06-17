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

=item $SOCKET_FILE

Socket to create/listen to for the CMDB daemon.  Matches the B<file> accessor.

=cut

our $SOCKET_FILE = "/tmp/cmdb-socket";
$FUNCTIONS{'socket_file'} = \$SOCKET_FILE;

=item $CONFIG

The location of the configuration file we're going to load to get defaults.
Defaults to F</etc/remedy/cmdb_config>; can be overridden either by passing
a different file name to B<load ()>, or by setting the environment variable
I<REMEDY_CMDB_CONFIG>.

Matches the B<config> accessor.

=cut

our $CONFIG        = '/etc/remedy/cmdb/config';
$FUNCTIONS{'config'} = \$CONFIG;

=item $CLASSES

Matches the B<classes_file> accessor.

=cut

our $CLASSES       = '/etc/remedy/cmdb/classes.csv';
$FUNCTIONS{'classes_file'} = \$CLASSES;

=item $SOURCES

=cut

our $SOURCES       = '/etc/remedy/cmdb/sources.csv';
$FUNCTIONS{'sources_file'} = \$SOURCES;

=item $REMEDY_CONFIG

=cut

our $REMEDY_CONFIG = '/etc/remedy/config';
$FUNCTIONS{'remedy_config'} = \$REMEDY_CONFIG;

=item $DEBUG_LEVEL

Defines how much debugging information to print on user interaction.  Set to
a string, defaults to I<$Log::Log4perl::ERROR>.  See B<Remedy::Log>.

Matches the I<loglevel> accessor.

=cut

our $DEBUG_LEVEL = $Log::Log4perl::ERROR;
$FUNCTIONS{'loglevel'} = \$DEBUG_LEVEL;

=item $LOGFILE

If set, we will append logs to this file.  See B<Remedy::Log>.

Matches the I<file> accessor.

=cut

our $LOGFILE = "";
$FUNCTIONS{'logfile'} = \$LOGFILE;

=item $LOGFILE_LEVEL

Like I<$DEBUG_LEVEL>, but defines the level of log messages we'll print to
I<$LOGFILE>.  Defaults to I<$Log::Log4perl::INFO>.  See B<Remedy::Log>.

Matches the B<logfile_level> accessor.

=cut

our $LOGFILE_LEVEL = $Log::Log4perl::INFO;
$FUNCTIONS{'loglevel_file'} = \$LOGFILE_LEVEL;

=back

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;

use Remedy::CMDB::Classes;
use Remedy::CMDB::Log;
use Remedy::CMDB::Sources;

my %opts;
foreach (keys %FUNCTIONS) { $opts{$_} = '$' }

struct 'Remedy::CMDB::Config' => { 
    'log'     => 'Remedy::CMDB::Log',
    'sources' => 'Remedy::CMDB::Sources',
    'classes' => 'Remedy::CMDB::Classes',
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

=item file ($)

=item log (B<Remedy::CMDB::Log>)

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
    do $file or die ("Couldn't load '$file': " . ($@ || $!) . "\n");
    my $self = $class->new ();

    $self->config ($file);
    _init_functions ($self);

    my $log = Remedy::CMDB::Log->new (
        'file'       => $self->logfile,
        'level'      => $self->loglevel,
        'level_file' => $self->loglevel_file,
    );
    $log->init;
    $self->log ($log);

    $self->sources_read ($self->sources_file);
    $self->classes_read ($self->classes_file);

    return $self;
}

sub sources_read {
    my ($self, $file) = @_;
    my $logger = $self->log->logger;

    $logger->debug ("loading sources from $file");
    my $sources = eval { Remedy::CMDB::Sources->read ($file) }
        or $logger->logdie ("couldn't read sources file: $@");

    $self->sources ($sources);
    $self->sources_file ($file);

    return $sources;
}

sub classes_read {
    my ($self, $file) = @_;
    my $logger = $self->log->logger;

    $logger->debug ("loading classes from $file");
    my $sources = eval { Remedy::CMDB::Classes->read ($file) }
        or $logger->logdie ("couldn't read classes file: $@");

    $self->classes ($sources);
    $self->classes_file ($file);

    return $sources;
}

sub mdr_to_dataset {
    my ($self, $mdr) = @_;
    return $self->sources->datasource ($mdr);
}

sub class_human_to_remedy {
    my ($self, $class) = @_;
    return $self->classes->human_to_remedy ($class);
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
