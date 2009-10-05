package Remedy::CMDB::Client;
our $VERSION = "0.50.00";
# Copyright and license are in the documentation below.

=head1 NAME

Remedy::CMDB::Client

=head1 SYNOPSIS

    use Remedy::CMDB::Client;

    my $string = eval { 
        Remedy::CMDB::Client->create_xml_string (\*STDIN) 
    };
    die "error on parsing XML: $@\n" if $@;
    die "no XML string" unless $string;

    my $client = eval { Remedy::CMDB::Client->connect };
    die "couldn't connect to CMDB: $@\n" unless $client;

    ## Figure out where we need to write
    my $socket = $client->socket;

    ## Actually do the writing.
    print $socket $string;

    ## That's the last we'll write to the socket, now we just have to read
    $socket->shutdown (1); 

    ## Print out everything that the socket writes back to us.
    while (<$socket>) { print }

    ## Close the socket and exit.
    $socket->close;
    exit 0;

=head1 DESCRIPTION

Remedy::CMDB::Client implements the client side of the CMDB registration
and query service.  It connects to an existing unix-domain socket (as
configured in B<Remedy::CMDB::Config>, writes a piece of XML, and waits for a
response.  

Remedy::CMDB::Client is implemented as a B<Class::Struct> object with some
additional functions.

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

## How many seconds do we want to wait for the socket to connect at all?
our $TIMEOUT = 10;

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Class::Struct;
use IO::Socket;
use Remedy::CMDB::Config;
use XML::Twig;
use XML::Writer::Raw;

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

=head2 B<Class::Struct> Subroutines 

=over 4

=item config B<Remedy::CMDB::Config>

Configuration information is stored in this object.

=item socket I<SOCKET>

The actual socket connection that we use to communicate with the
B<Remedy::CMDB::Server> service.  Created with B<create ()>.

=item socketfile I<FILENAME>

The name of the file containing the unix domain socket.  Obtained from the
B<Remedy::CMDB::Config> object.

=item timeout I<SECONDS>

How many seconds should we allow to connect to the server?  Defaults to 10.

=back

=cut

##############################################################################
### Object Construction ######################################################
##############################################################################

=head2 Construction

=over 4

=item connect ([PORT [, ARGHASH]])

Creates the B<Remedy::CMDB::Client> object, and connects to the unix domain
socket at the file specified by B<socketfile ()>.  

=over 4

=item timeout (I<SECONDS>)

Override the default timeout value.

=back

Returns the new B<Remedy::CMDB::Client> object on success, or does on failure.

=cut

sub connect {
    my ($class, %args) = @_;
    my $self = $class->new;

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

=back

=cut

##############################################################################
### Socket Routines ##########################################################
##############################################################################

=head2 Socket Routines 

=over 4

=item client_open (FILENAME)

Opens I<FILENAME> as a B<IO::Socket::UNIX> object, and sets the values of
B<socket ()> and B<socket_file ()> appropriately.  Returns the socket object
on success, or dies on failure.  If we are already connected, then we'll just
return the existing socket object.

This is generally invoked by B<connect ()>.

=cut

sub client_open {
    my ($self, $file) = @_;
    my $logger = $self->logger_or_die;
    return $self->socket if $self->socket;

    $logger->logdie ("no file at which to open socket") unless $file;

    $logger->debug ("opening socket at $file");

    my $timeout = $self->timeout;
    my $client = IO::Socket::UNIX->new ('Peer' => $file,
        Type => SOCK_STREAM, 'Timeout' => $self->timeout) 
        or $logger->logdie ("socket open failed: $@\n");
    $logger->warn ("talking to $file");

    $self->socket   ($client);
    $self->socketfile ($file);
    return $self->socket;
}

=item client_close ()

Shuts down an existing connection.  If we're not already connected, then we
will just return undef; otherwise, we will return the error code of the close.

=cut

sub client_close {
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

=back

=cut

##############################################################################
### Miscellaneous ############################################################
##############################################################################

=head2 Miscellaneous 

=over 4

=item create_xml_string (SOURCE)

Given a stream of XML on file handle I<SOURCE>, parses it with XML::Twig to
confirm that the XML is good, and then wraps it in information about the local
environment (as pulled from %ENV).  This ends up looking something like this:

    <cmdb-client>
        <environment>
            <PLATFORM>linux</PLATFORM>
            <LOGIN>tskirvin</LOGIN>
            <KRB5CCNAME>[...]</LOGIN>
            [...]
        </environment>
        <request>
            [original XML]
        </request>
    </cmdb-client>

B<CMDB::Server> knows how to parse this appropriately.

=cut

sub create_xml_string {
    my ($self, $source) = @_;

    # just make sure the XML is good
    my $twig = XML::Twig->new ('no_prolog' => 1);
    $twig->safe_parse (join ('', <$source>)) or die "bad XML: $@\n";

    my $string;
    my $writer = XML::Writer::Raw->new ('OUTPUT' => \$string,
        'DATA_INDENT' => 4, 'NEWLINES' => 0, 'DATA_MODE' => 1, 'UNSAFE' => 1);
    $writer->xmlDecl ();
    $writer->startTag ('cmdb-client');
    {   
        $writer->startTag ('environment');
        foreach my $key (sort keys %ENV) {
            $writer->dataElement ($key, $ENV{$key});
        }
        $writer->endTag;

        my %args = ('pretty_print' => 'indented');  # was indented_a
        $writer->startTag ('request');
        $writer->setDataIndent ($writer->getDataIndent + 4);  ## HACK
        $writer->write_raw_with_format ($twig->sprint (%args));
        $writer->setDataIndent ($writer->getDataIndent - 4);  ## HACK
        $writer->endTag ('request');

    }
    $writer->endTag;
    $writer->end;

    return $string;
}

=back

=cut

##############################################################################
### Internal Subroutines #####################################################
##############################################################################

# eventually, we sohuld keep the logger in the object, but not yet
sub logger_or_die { 
    my ($self) = @_;
    return unless $self->config;
    $self->config->log->logger;
}

## We don't have one right now; perhaps we should add one.
sub DESTROY { }

##############################################################################
### Final Documentation ######################################################
##############################################################################

=head1 REQUIREMENTS

B<Remedy::CMDB::Config>, B<XML::Twig>, B<XML::Writer::Raw>

=head1 SEE ALSO

cmdb-register(1), Remedy::CMDB::Server(3).

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
