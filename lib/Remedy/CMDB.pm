package Remedy::CMDB;
our $VERSION = "0.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

=head1 VARIABLES

These variables primarily hold human-readable translations of the status,
impact, etc of the ticket; but there are a few other places for customization.

=over 4

=item $CONFIG

=cut

=back

=cut

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;

use Remedy;
use Remedy::CMDB::Config;
use Remedy::CMDB::Log;

struct 'Remedy::CMDB' => {
    'config'    => 'Remedy::CMDB::Config',
    'logobj'    => 'Remedy::CMDB::Log',
    'remedy'    => 'Remedy',
};

##############################################################################
### Subroutines ##############################################################
##############################################################################

sub connect {
    my ($class, %args) = @_;
    my $self = $class->new;

    ## Load and store configuration information
    my $config = $args{'config'} || '';
    my $conf = ref $config ? $config 
                           : Remedy::CMDB::Config->load ($config);
    $self->config ($conf);

    ## Get and save the logger
    $self->logobj ($self->config->log);
    if (my $debug = $args{'debug'}) { $self->logobj->more_logging ($debug); }

    ## From now on, we can print debugging messages when necessary
    my $logger = $self->logger_or_die ('no logger at init');

    ## Create and save the Remedy object
    $logger->debug ("creating remedy object");
    { 
        local $@;
        my $remedy = eval { Remedy->connect ('config' => $conf->remedy_config) }
            or $logger->logdie ("couldn't start Remedy session: $@");
        $self->remedy ($remedy);
    }

    return $self;
}

sub logger { shift->logobj_or_die->logger (@_) }

sub config_or_die { shift->_or_die ('config', "no configuration", @_) }
sub logobj_or_die { shift->_or_die ('logobj', "no logger",        @_) }
sub logger_or_die { shift->_or_die ('logger', "no logger",        @_) }
sub remedy_or_die { shift->_or_die ('remedy', "no remedy",        @_) }

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

### _or_die (TYPE, ERROR, EXTRATEXT, COUNT)
# Helper function for Class::Struct accessors.  If the value is not defined -
# that is, it wasn't set - then we will immediately die with an error message
# based on a the calling function (can go back extra levels by offering
# COUNT), a generic error message ERROR, and a developer-provided, optional
# error message EXTRATEXT.  
sub _or_die {
    my ($self, $type, $error, $extra, $count) = @_;
    return $self->$type if defined $self->$type;
    $count ||= 0;

    my $func = (caller ($count + 2))[3];    # default two levels back

    chomp $extra if defined $extra;
    my $fulltext = sprintf ("%s: %s", $func, $extra ? "$error ($extra)"
                                                    : $error);
    die "$fulltext\n";
}

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Class::Struct>, B<Remedy>

=head1 SEE ALSO

Remedy(8)

=head1 HOMEPAGE

TBD.

=head1 AUTHOR

Tim Skirvin <tskirvin@stanford.edu>

=head1 LICENSE

Copyright 2009 Board of Trustees, Leland Stanford Jr. University

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
