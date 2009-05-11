package Remedy::CMDB::Server;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

our $SOCKET   = "/tmp/cmdb";
our $MAXCONN  = 10;  
our $PROTOCOL = SOCK_DGRAM; 

our $NEWLINE = "\r\n";

our %COMMANDS = (
    'QUIT'     => \&quit,
    'REGISTER' => \&register,
);

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use IO::Socket;

use Remedy::CMDB;

struct 'Remedy::CMDB::Server' => {
    'cmdb'       => 'Remedy::CMDB',
    'socket'     => '$',
    'socketfile' => '$',
};

our $LOGGER = Remedy::CMDB::Log->get_logger;

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

    $LOGGER->debug ("creating Remedy::CMDB object");
    { 
        local $@;
        my $cmdb = eval { Remedy::CMDB->connect (%args) }
            or die "couldn't create CMDB object: $@\n";
        $self->cmdb ($cmdb);
    }
    
    my $logger = $self->cmdb->logger_or_die;
    my $config = $self->cmdb->config_or_die;

    $logger->debug ("creating local socket connection");
    { 
        local $@;
        my $socket_file = $config->socket_file 
            or $logger->logdie ("no socket file");
        my $socket = eval { $self->server_open ($socket_file) };
        unless ($socket && ref $socket) { 
            $@ =~ s/ at .*$//;
            $logger->error ($socket) if $socket;
            $logger->logdie ("error on socket_open: $@");
        }
    }

    return $self;
}

sub process {
    my ($self, $client, $line) = @_;
    
    print $client $line;
    return;
}

sub server_open {
    my ($self, $file) = @_;
    my $logger = $self->logger_or_die;
    $logger->logdie ("no file to write a socket to") unless $file;

    $self->server_close;
    if (-e $file) { 
        $logger->debug ("removing existing $file");
        unlink $file || $logger->logdie ("could not unlink $file: $@");
    }
    $logger->all ("opening socket at $file");

    my $server = IO::Socket::UNIX->new ('Local' => $file,
        Type => SOCK_STREAM, 'Listen' => 1) 
        or die "failed to open socket: $@\n";
    $logger->all ("listening at $file");

    # may want to set permissions here

    $self->socket   ($server);
    $self->socketfile ($file);

    return $self->socket;
}

sub server_close {
    my ($self) = @_;
    my $logger = $self->logger_or_die;
    if (my $socket = $self->socket) {
        if (my $file = $self->socketfile) {
            $logger->warn ("removing file $file");
            unlink $file if -e $file;
        }

        $logger->warn ("closing socket");
        $self->socket     ('');
        $self->socketfile ('');
        return close $socket;
    } 
    return;
}

sub disconnect {
    my ($self, $fh) = @_;
    return unless $fh;
    return unless defined socketno ($fh);
    close $fh;
}

sub process {
    my ($self, @xml) = @_;
    return @xml;
}

# eventually, we'll keep the logger in the object, but not yet
sub logger_or_die { 
    my ($self) = @_;
    return unless $self->cmdb;
    $self->cmdb->logger_or_die;
}


=back

=cut

##############################################################################
### Commands #################################################################
##############################################################################

sub quit {
    my ($self, $fh) = @_;
    return unless ($fh && defined fileno ($fh));
    return close $fh;
}

sub register {
    my ($self, $fh) = @_;
    return unless ($fh && defined fileno ($fh));
    print $fh "Send XML to be validated" . $NEWLINE;
    my @lines = ();
    while (<$fh>) { 
        my $line = $_;
        $_ =~ s/(\r?\n|\n?\r)$//g;
        last if $line eq '.';
        push @lines, $line;
    }
    print $fh "we would now do something useful with the XML";
}

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

#sub DESTROY { 
#    my ($self) = @_;
#    $self->server_close if $self->socket;
#}

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;


