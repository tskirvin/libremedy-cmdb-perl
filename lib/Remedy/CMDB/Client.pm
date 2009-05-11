package Remedy::CMDB::Client;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $TIMEOUT = 10;

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use IO::Socket;

use Remedy::CMDB::Config;

struct 'Remedy::CMDB::Client' => {
    'config'     => 'Remedy::CMDB::Config',
    'socket'     => '$',
    'socketfile' => '$',
    'timeout'    => '$'
};

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item open ([PORT [, ARGHASH]])

=cut

sub connect {
    my ($class, %args) = @_;
    my $self = $class->new ();

    my $config = $args{'config'} || '';
    my $conf = ref $config ? $config 
                           : Remedy::CMDB::Config->load ($config);
    $self->config ($conf);
    my $logger = $conf->log->logger;

    $self->timeout ($args{'timeout'} || $TIMEOUT);

    ## Connect to the local socket
    my $socket_file = $conf->socket_file or $logger->logdie ("no socket file");
    my $socket = $self->client_open ($socket_file)
        or $logger->logdie ("couldn't open socket: $@");

    return $self;
}

sub client_open {
    my ($self, $file) = @_;
    my $logger = $self->logger_or_die;
    return $self->socket if ($self->socket);

    $logger->logdie ("no file at which to open socket") unless $file;

    $logger->debug ("opening socket at $file");

    my $timeout = $self->timeout;
    my $client = IO::Socket::UNIX->new ('Peer' => $file,
        Type => SOCK_STREAM, 'Timeout' => $self->timeout) 
        or $logger->logdie ("couldn't read from socket: $@");
    $logger->warn ("talking to $file");

    $self->socket   ($client);
    $self->socketfile ($file);
    return $self->socket;
}

sub server_close {
    my ($self) = @_;
    my $logger = $self->logger_or_die;
    if (my $socket = $self->socket) {
        $logger->warn ("closing socket");
        $self->socket (undef);
        return close $socket;
    } else {
        $logger->warn ("no connection to close");
        return;
    }
}

# eventually, we'll keep the logger in the object, but not yet
sub logger_or_die { 
    my ($self) = @_;
    return unless $self->config;
    $self->config->log->logger;
}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

sub DESTROY { }

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
