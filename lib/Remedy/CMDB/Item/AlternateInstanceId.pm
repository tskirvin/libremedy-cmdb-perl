package Remedy::CMDB::Item::AlternateInstanceID;

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Remedy::CMDB::Template::ID;

our @ISA = qw/Remedy::CMDB::Template::ID/;

##############################################################################
### Overrides ################################################################
##############################################################################

sub tag_type { "alternateInstanceId" }

1;
