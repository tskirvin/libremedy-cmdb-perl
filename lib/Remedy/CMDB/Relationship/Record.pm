package Remedy::CMDB::Relationship::Record;

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Remedy::CMDB::Template::Record;

our @ISA = qw/Remedy::CMDB::Template::Record/;

##############################################################################
### Overrides ################################################################
##############################################################################

sub tag_type { "record" }

1;
