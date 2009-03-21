#!/usr/local/bin/perl -Tw
# -*- Perl -*- Mon Mar 29 10:09:55 CST 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>
# Copyright 2000-2004 Tim Skirvin; redistribution terms are below.
###############################################################################

use vars qw( $PORT $DEBUG $TIMEOUT @MACHINES $MAXKIDS @CLIENTS $VERSION );
$VERSION = "0.72b";

###############################################################################
### CONFIGURATION + PRIVATE DATA ##############################################
###############################################################################

## Modify and uncomment this to use user modules instead of system-wide 
## ones.  You'll need this unless you're installing as root.  

# use lib '/PATH/TO/USER/CODE';

## Which machines should we connect to?  For now, just put in references
## to Net::NNTP::Client objects (authentication will be taken care of later).

use Net::NNTP::Client;

@CLIENTS = (
	new Net::NNTP::Client('news.ks.uiuc.edu'),
	   );

## Which machines can we cannect from?  List them off; regexps are fine.

@MACHINES   = qw( localhost .*.ks.uiuc.edu .*.killfile.org );

## Choose which port to connect to.  Note that '119' is the standard NNTP
## port, but in order to connect to it you must be root!  

$PORT       = 9119;		  

## Should we print debugging information?  1 for yes, 0 for no.

$DEBUG      = 1;		  

## How many children should we allow running at a time?  This also works
## out to the maximum number of processes.  (Note that posting processes
## also take a child).

$MAXKIDS    = 5; 		

## How long should it take before a connection times out?  This should be 
## set to slightly below the lower-bound of the timeouts of any of the
## servers you connect to; the number is in seconds.

$TIMEOUT    = 900;	# 15 minutes

###############################################################################
### main() ####################################################################
###############################################################################

use Net::NNTP::Client;
use Net::NNTP::Proxy;
use News::NNTPAuth;
use Net::NNTP;
use strict;
use Sys::Hostname;
use Getopt::Std;
use POSIX qw(:sys_wait_h :signal_h :errno_h);
use Errno;
use Socket;

use vars qw( $CHILDREN $SERVER $opt_p $opt_d $opt_v $opt_h );
$CHILDREN = 0;
$SIG{CHLD} = \&reaper; 		   # Set what to do when the children die.

$|++;	

# Trim the path name off of the program
$0 =~ s%.*/%%;

# Get the path information
getopts('p:dhv');
Usage()   if $opt_h;
Version() if $opt_v;
if ($opt_d) {
  $DEBUG ||= $opt_d;
  $Net::NNTP::Client::DEBUG ||= $opt_d;
  $Net::NNTP::Proxy::DEBUG ||= $opt_d;
  $News::NNTPAuth::DEBUG    ||= $opt_d;
}
if ($opt_p && $opt_p =~ /^(\d+)$/) { $PORT  = $1; } 	

# Create the server, and make it listen for a connection
my $SERVER = new Net::NNTP::Proxy()
	|| die "Couldn't start the server: $!\n";
$SERVER->openport($PORT) || die "Couldn't listen on port $PORT: $!\n";

# Generate the servers list 
foreach my $server (@CLIENTS) {
  # Load up the authentication information with NNTPAuth, if possible
  my ($nntpuser, $nntppass) = News::NNTPAuth->nntpauth($server->server);  
  $server->user($nntpuser) if $nntpuser;  
  $server->pass($nntppass) if $nntppass;

  # Connect to the news server now, or forever hold your peace.
  $server->connect ? $SERVER->push($server)
  		   : warn "Couldn't connect to " . $server->name . ": $!\n";
}


# Accept and process the connections
while (my $CLIENT = $SERVER->connect) {
  while ($CHILDREN >= $MAXKIDS) { sleep 1 }  # Only allow $MAXKIDS servers
  next unless defined fileno($CLIENT);		# Socket not open -> stop
  next unless my $ip = validate($CLIENT);
  
  # Fork off more clients; if we're above $MAXKIDS, though, wait for a
  # while and try again.  (This ought to have a real timeout, I guess)
  unless (my $count = _fork($CLIENT)) {
    next unless defined $count;
    $CHILDREN++; warn "Clients: $CHILDREN\n" if $DEBUG;
    next;
  }

  $SERVER->closeport; 	# child closes unused handle
  select($CLIENT);
  $| = 1;		# autoflush

  my $servers = 0;
  # Reconnect to the servers, if we're not already connected to them
  foreach my $server (@{$SERVER->newsservers}) {
    $server->reconnect && $servers++;
  }
  # If we couldn't connect, quit in disgust
  unless ($servers) {
    print $CLIENT "505 Couldn't connect to other servers\n";
    select(\*STDOUT);
    exit(0);
  }

  # We're done as root, if we needed to be; change to UID 1
  if ($> == 0) { $> = 1 }  

  # Put the server into reader mode.
  $SERVER->process($CLIENT, 'mode reader');

  # Central loop - every time there's input, do something with it.
  my $time = time;
  while (<$CLIENT>) {		
    if (time - $TIMEOUT > $time) { 
      print STDOUT "$ip: timeout\n" if $DEBUG; last;
    } else { $time = time }
    chomp;  
    next unless (defined($_) && $_ =~ /\S/);   
    print STDOUT "$ip: $_\n" if $DEBUG;
    last unless defined fileno($CLIENT);	# Socket not open -> stop
    $SERVER->process($CLIENT, $_) || last;
  }

  # Close up and exit.
  close $CLIENT;
  select(\*STDOUT);
  $SERVER->process($CLIENT, 'quit');
  exit 0;
}

$SERVER->closeport;
exit 0;

###############################################################################
### Functions #################################################################
###############################################################################

# Make sure that the connection is valid.  Code taken from Programming 
# Perl 3rd Edition (mostly).  Not yet done, really; I'm not sure what 
# kind of behaviour this is going to become, or where it's going to sit.

sub validate {
  my $socket = shift || return undef;
  return undef unless defined fileno($socket);	# Not an open socket -> skip it
  my $peername = getpeername($socket) || return undef;  
  my ($port, $iaddr) = unpack_sockaddr_in($peername);
  my $ip = inet_ntoa($iaddr);
  my $hostname = gethostbyaddr($iaddr, AF_INET);
  my $okay = 0;
  foreach (@MACHINES) { $okay = 1 if ($hostname =~ /^$_$/); }
  warn $okay ? "Connection from $hostname ($ip)\n" 
	     : "Refusing connection: $hostname ($ip)\n" if $DEBUG;
  return $ip if $okay;
  print $socket "502 Permission Denied\n";
  close $socket;
  return undef;
}

### _fork ( FILEHANDLE )
# Just the fork code.  
sub _fork {
  my $fh = shift;  return undef unless $fh && defined fileno($fh);
  if (my $pid = fork) {         # Success, and we're the parent
    close $fh;                  #   -> close the fh, return 0, and
    return 0;                   #   wait for the next call
  } elsif ( defined $pid ) {    # Success, and we're a child
    return 1;                   #   -> return something, so we can keep going
  } elsif ( $! == EAGAIN ) {    # Retry - this is the "do again" thing
    sleep 5;
    return _fork($fh);
  } else {
    die "Cannot fork: $!\n";
    return undef;
  }
}

### reaper ( PID ) 
# Takes care of cleaning up the children processes.  Probably doesn't work
# perfectly; it's not overly well tested or anything.  Please report bugs
# with this, and fixes for them, ASAP.  Thanks, kind reader.  
sub reaper { 
  my $kid = waitpid(-1, WNOHANG);
  if ($kid == -1) { 		# no child waiting; ignore
  } elsif (WIFEXITED($?)) {	# Process exited
    $CHILDREN--;
    warn "Client reaped, $CHILDREN remain\n" if $DEBUG;
    reaper();			# Make sure there's no more left
  } else {  			# False alarm; ignore
  }
}

### Usage() 
# Prints usage information and exits.

sub Usage {
  warn <<EOM;

$0 v$VERSION
an NNTP reader and server
Usage: $0 [-hvd] [-p port]

A news server written in perl, which gets its information from other news
servers.  Its primary purpose is to allow a standard newsreader to read
news from more than one site.  More information is available in its manual
page.

	-h		Print this message and exit.
	-v 		Print the version number and exit.
	-d		Print debugging information.
	-p port		Bind to 'port' instead of the default ($PORT)
			  (Note that the standard news port is 119; 
			   you must be root to bind there, though.)
EOM

  exit(0);
}

### Version()
# Prints version information and exits.

sub Version {
  warn "$0 v$VERSION\n";
  exit(0);
}

=head1 NAME

newsproxy.pl - a perl-based Usenet "proxy" server 

=head1 SYNOPSIS

newsproxy.pl [-hvd] [-p port]

=head1 DESCRIPTION

newsproxy.pl is a proxying news server, meaning that it doesn't actually
maintain any information locally - everything it gets is off of other news
servers.  This is useful for several reasons, the most obvious of which is
to allow a user to read news off of more than one server at a time.  As
different servers contain different groups, this is important.  

Other benefits:

  o Allows non-NNTPAUTH capable news readers to connect to NNTPAUTH
    enabled news servers.
  
  o Allows the same newsgroup to be read on two different news servers, 
    allowing users to choose their filtering policies more carefully.

  o Allow for overview-only feeds to allow users to share their idea of
    what a given group should look like.  (Not currently supported by any 
    servers, but it'd be interesting) 

  o Allows for fast access to "local" articles, even on remote and slow 
    servers, as long as 
  
  o Gives a framework to add additional news services, such as a news
    cache.

newsproxy.pl is based around two perl modules - Net::NNTP::Client and
Net::NNTP::Proxy.  Please see their manual pages for more details.

=cut

=item USAGE

  newsproxy.pl [-hvd] [-p port]

    -h	     Prints a short help message and exits.
    -v       Print the version number and exit.
    -d       Print debugging information.
    -p port  Bind to 'port' instead of the default ($PORT).  

=head1 NOTES

As it does require root priv's to bind to port 119, this code is designed
to drop down to user-level permissions (UID = 1) once it's done so - there
isn't a need to have this thing running around as root.

=head1 REQUIREMENTS

Requires Perl 5 or better, Net::NNTP, News::Article (for Net::NNTP::Proxy), 
Errno, and the NewsLib modules (News::NNTPAuth, Net::NNTP::Proxy, and 
Net::NNTP::Client).  

=head1 SEE ALSO

L<Net::NNTP>, L<Net::NNTP::Proxy>, L<Net::NNTP::Client>

=head1 TODO

=over 4

=item Add in the rest of the functionality of INN 

authinfo, help, ihave, list, newgroups, newnews, slave, xgtitle, xhdr, 
xpat, xpath) currently don't work.  (This is part of the Net::NNTP::Proxy
module).

=item Create a real admin interface

An extension to NNTP would make life easier here - use authinfo and such,
so that you can log into a server and automatically get a list of groups
rather than having to set these variables here on your own.

=item Make this thing into a daemon

Start it and forget it.  Alternately, it might be neat to add this into 
inetd.conf.

=item Write some better code for handling the children.  

=item Implement real authentication, and NNTPS.

=item Work on other related projects, like an NNTP cache.

=back

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 LICENSE

This code may be used and/or distributed under the same terms as Perl
itself.  Note that this is beta code; use it at your own risk.

=head1 COPYRIGHT

Copyright 2000-2004 Tim Skirvin <tskirvin@killfile.org>

=cut

### Version History
# v0.5a 	Wed Nov  8 16:39:29 CST 2000
#   First version that's ready for release.  Still needs to be better
#   driven as a daemon, and real authentication.
# v0.6b		Mon Aug 27 15:27:31 CDT 2001
#   Drops to user permissions after it binds to port, if it was running as
#   root.  Some changes were made to Net::NNTP::Client to allow for better
#   reconnections.  Fixed up the validation problems - patterns now work.
#   Updated the documentation.
# v0.72b	Mon Mar 29 10:10:00 CST 2004 
#   I don't really know what happened in previous incarnations...  Added 
#   a timeout function.
