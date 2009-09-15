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

our $SOCKET   = "/tmp/cmdb-socket";
our $MAXCONN  = 32;  
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
use Remedy::CMDB::Client::XML;
use Remedy::CMDB::Client::Response;

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

sub server_open {
    my ($self, $file, %args) = @_;
    my $logger = $self->logger_or_die;
    $logger->logdie ("no file to write a socket to") unless $file;

    my $max = defined $args{'maxconn'} ? $args{'maxconn'} 
                                       : $MAXCONN;

    $self->server_close;
    if (-e $file) { 
        $logger->debug ("removing existing $file");
        unlink $file || $logger->logdie ("could not unlink $file: $@");
    }
    $logger->all ("opening socket at $file");

    my $server = IO::Socket::UNIX->new ('Local' => $file, Type => SOCK_STREAM, 
        'Listen' => $max) or die "failed to open socket: $@\n";
    $logger->all ("listening at $file");

    $self->socket   ($server);
    $self->socketfile ($file);

    return $self->socket;
}

sub socket_close {
    my ($self) = @_;
    if (my $socket = $self->socket) { close $socket }
}

sub server_close {
    my ($self) = @_;
    my $logger = $self->logger_or_die;

    if (my $file = $self->socketfile) {
        if (-e $file) { 
            $logger->warn ("removing socket '$file'");
            unlink $file if -e $file;
        }
    }

    $self->socketfile ('');
    if (my $socket = $self->socket) {
        $logger->warn ("closing socket");
        $self->socket ('');
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
    my ($self, $client, @xml) = @_;
    my $logger = $self->logger_or_die;
    
    my $register;
    {   
        local $@;
        $register = eval { Remedy::CMDB::Client::XML->read ('xml', 
            'type' => 'stream', 'source' => join ('', @xml)) };
        if ($@) { 
            $logger->fatal ("invalid XML: $@");
            return "invalid xml: $@\n" unless $register;
        }
    }
    return $self->error ("could not create registration object: $@") unless $register;

    my $class = $register->class;
    my $query = $register->query;
    
    $logger->debug ("doing a $class query on $query");

    ## Make sure the mdrId is set; we'll match it in a second
    my $mdr_parent = $query->mdrId || 
        return $self->error ("no mdrId in source XML");
    $logger->debug ("mdr_parent is $mdr_parent");

    ## Now make sure the mdrId matches a valid dataset
    my $dataset = $self->cmdb->config->mdr_to_dataset ($mdr_parent) 
        || return $self->exit_error ("no dataset mapping for $mdr_parent");
    $LOGGER->debug ("associated dataset is $dataset");

    ## TODO: kerberos principal check

    my $response = $query->register_all ($self->cmdb, 
        'dataset' => $dataset, 'mdr' => $mdr_parent);
    return scalar $response->xml;
}

# eventually, we'll keep the logger in the object, but not yet
sub logger_or_die { 
    my ($self) = @_;
    return unless $self->cmdb;
    $self->cmdb->logger_or_die;
}

sub error { 
    my ($self, $text, %args) = @_;
    my $logger = $self->logger_or_die;
    my $response = $args{'response'} || $self->response;
    $response->add_error ('global', $text);
    $logger->fatal ($text);
    return scalar $response->xml;
}

sub response { shift; Remedy::CMDB::Client::Response->new (@_) }

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


