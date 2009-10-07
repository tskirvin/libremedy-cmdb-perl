package Remedy::CMDB::Server;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Server - the server side of the Remedy CMDB implementation

=head1 SYNOPSIS

    use Remedy::CMDB::Server;
    # please look at cmdb-server for some sample code

=head1 DESCRIPTION

Remedy::CMDB::Server implements the server side of the CMDB registration and
query service.  It creates and opens a unix-domain socket (as configured in
B<Remedy::CMDB::Config>, and listens on it for XML-formatted input.  Every time
it gets some input, it processes it and returns an XML response over that same
socket.

Remedy::CMDB::Server is implemented as a B<Class::Struct> object with some
additional functions.

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

## Default name of the 
our $SOCKET   = "/var/lib/cmdb/cmdb-socket";

## Maximum number of connections 
our $MAXCONN  = 32;  

## What protocol are we speaking over the socket?
our $PROTOCOL = SOCK_DGRAM; 

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use IO::Socket;
use Remedy::CMDB;
use Remedy::CMDB::Server::XML;
use Remedy::CMDB::Server::Response;

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

=head2 B<Class::Struct> Subroutines 

=over 4

=item cmdb B<Remedy::CMDB>

=item socket I<SOCKET>

The actual socket connection that we use to communicate with the
B<Remedy::CMDB::Client> service.  Created with B<create ()>.

=item socketfile I<FILENAME>

The name of the file containing the unix domain socket.  Obtained from the
B<Remedy::CMDB::Config> object associated with B<cmdb ()>.

=back

=cut

##############################################################################
### Object Construction ######################################################
##############################################################################

=head2 Construction

=over 4

=item connect (ARGHASH)

Creates the B<Remedy::CMDB::Server> object, and opens the unix domain socket
at the file specified by B<socketfile ()>. Pulls additional arguments from the
hash I<ARGHASH>:

=over 4

=item debug I<LEVEL>

Turn on extra debugging infromation.  Note that this information is saved to
the file specified in B<Remedy::CMDB::Log>.

=back

Returns the new B<Remedy::CMDB::Server> object on success, or dies on failure.

=cut

sub connect {
    my ($class, %args) = @_;
    my $self = $class->new ();

    $LOGGER->debug ("creating Remedy::CMDB object");
    my $cmdb = eval { Remedy::CMDB->connect (%args) }
        or die "couldn't create CMDB object: $@\n";
    $self->cmdb ($cmdb);

    if (my $debug = $args{'debug'}) { 
        $cmdb->config->log->more_logging ($debug) 
    }
    
    my $logger = $self->cmdb->logger_or_die;
    my $config = $self->cmdb->config_or_die;

    $logger->debug ("creating local socket connection");
    my $socket_file = $config->socket_file 
        or $logger->logdie ("no socket file");
    my $socket = eval { $self->server_open ($socket_file) };
    unless ($socket && ref $socket) { 
        $@ =~ s/ at .*$//;
       $logger->error ($socket) if $socket;
       $logger->logdie ("error on socket_open: $@");
    }

    return $self;
}

=back

=cut

##############################################################################
### Socket Routines ##########################################################
##############################################################################

=head2 Socket Routines 

=over 4

=item server_open (FILENAME, ARGHASH)

Opens I<FILENAME> as a B<IO::Socket::UNIX> object, and sets the values of
B<socket ()> and B<socket_file ()> appropriately.  Returns the socket object
on success, or dies on failure.  If we are already connected, then we'll just
return the existing socket object.

This is generally invoked by B<connect ()>.

=cut

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

    ## TODO: do we want different permissions here?  Probably.
    chmod (0777, $file);

    return $self->socket;
}

=item server_close ()

Close the server entirely, meaning that we'll both close the socket and remove
the socket file.

=cut

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

=item socket_close ()

Close the socket for the current connection.  

=cut

sub socket_close {
    my ($self) = @_;
    if (my $socket = $self->socket) { close $socket }
}

=back

=cut

##############################################################################
### Input/Output #############################################################
##############################################################################

=head2 Input/Output

=over 4

=item process (CLIENT, XML)

Process the array of text in I<XML>.  This generally means loading the XML with
B<Remedy::CMDB::Server::XML>, checking the parent MDR to see that it's a valid
class and that we're allowed to write to it, and running everything through
B<register_all ()>.  We return the XML of the response.

I<CLIENT> is not currently used, but is saved for better multi-threading in the
future.

=cut

sub process {
    my ($self, $client, @xml) = @_;
    my $logger = $self->logger_or_die;
    
    my $register = eval { Remedy::CMDB::Server::XML->read ('xml', 
        'type' => 'stream', 'source' => join ('', @xml)) };
    if ($@) { 
        $logger->fatal ("invalid XML: $@");
        return "invalid xml: $@\n" unless $register;
    }
    return $self->error ("could not create registration object: $@") 
        unless $register;

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

    ## TODO: kerberos principal check goes here.
    # $self->config->sources->validate_principal ($mdr_parent, $register->env
    #   ('KRB5CCNAME'));

    my $response = $query->register_all ($self->cmdb, 
        'dataset' => $dataset, 'mdr' => $mdr_parent);
    return scalar $response->xml;
}

=back

=cut

##############################################################################
### Miscellaneous ############################################################
##############################################################################

=head2 Miscellaneous 

=over 4

=item error (TEXT, ARGHASH)

Returns an XML-formatted error message to the client, because something went
wrong.  Takes the following arguments from I<ARGHASH>:

=over 4

=item response I<RESPONSE>

Uses I<RESPONSE> instead of making a new one.

=back

Returns the XML of the response.

=cut

sub error { 
    my ($self, $text, %args) = @_;
    my $logger = $self->logger_or_die;
    my $response = $args{'response'} || $self->response;
    $response->add_error ('global', $text);
    $logger->fatal ($text);
    return scalar $response->xml;
}

=item response (ARGS)

Create and return a new B<Remedy::CMDB::Server::Response>.

=cut

sub response { shift; Remedy::CMDB::Server::Response->new (@_) }

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

=head2 Internal Subroutines 

=over 4

=item logger_or_die ()

Return the current logger object (obtained through B<cmdb ()>) or die.

=cut

# eventually, we sohuld keep the logger in the object, but not yet
sub logger_or_die { 
    my ($self) = @_;
    return unless $self->cmdb;
    $self->cmdb->logger_or_die;
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 TODO

We are not currently doing the requisite Kerberos principal check, and won't be
until we're a bit closer to going into production.  Note, though, that the code
is at least written.

=head1 REQUIREMENTS
 
B<Remedy::CMDB>, B<Remedy::CMDB::Server::XML>

=head1 SEE ALSO

cmdb-server(8), Remedy::CMDB::Client(3).

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
