package Remedy::CMDB::Daemon;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $DEBUG = 0;      

our $MAX_CONN = 10;  # maximum number of connections

our $PORT  = '';     # must declare a port;
our $PROTO = 'tcp'; 

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use Log::Log4perl;
use Socket;

struct 'Remedy::CMDB::Daemon' = {
    'config'   => 'Remedy::CMDB::Daemon::Config',
    'maxconn'  => '$',
    'parent'   => 'Remedy::CMDB',
    'protocol' => '$',
    'port'     => '$',
    'server'   => '$',
    'socket'   => '$',
}

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item open ([PORT [, ARGHASH]])

=cut

sub open {
    my ($self, $port, %args) = @_;
    my $logger = $self->logger_or_die;

    $port ||= $self->port || $PORT;
    return undef unless $port;

    my $maxconn  = $args{'maxconn'}  || $self->maxconn  || $MAXCONN;
    my $protocol = $args{'protocol'} || $self->protocol || $PROTOCOL;
    return unless ($maxconn && $protocol);

    # create the socket
    socket (SERVER, PF_INET, SOCK_STREAM, getprotobyname ($protocol));

    # so we can restart our server quickly
    setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
  
    # build up my socket address
    unless (bind (SERVER, sockaddr_in($port, INADDR_ANY) ) ) {
        $logger->error ("couldn't bind to port $port: $@");
        return;
    }
  
    # establish a queue for incoming connections 
    unless (listen(SERVER, $maxconn || $MAXCONN || SOMAXCONN) ) {
        $logger->error ("couldn't listen on port $port: $@");
        return;
    }
    $self->warn ("Listening on port $port");
    
    $self->port ($port);
    $self->socket (\*SERVER);

    return $self->socket;
}

sub close {
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

=item connect (FILEHANDLE)

=cut

sub connect {
    my ($self, $fh) = @_;   
    my $socket = $self->socket || return;
    $fh ||= \*CLIENT;
    accept ($fh, $server);
    return $fh;
}

sub disconnect {
    my ($self, $fh) = @_;
    return unless $fh;
    return unless defined fileno ($fh);
    close $fh;
}

sub process {
    my ($self, $fh, $line) = @_;
    
}


=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;


