package Remedy::CMDB::Item::Response;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Template::ResponseItem;

our @ISA = qw/Remedy::CMDB::Template::ResponseItem/;

##############################################################################
### Overrides ################################################################
##############################################################################

sub tag_type   { "itemResponse" }

1;
