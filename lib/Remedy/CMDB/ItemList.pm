package Remedy::CMDB::ItemList;

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;

use Remedy::CMDB::Template::List;
use Remedy::CMDB::Item;

our @ISA = qw/Remedy::CMDB::Template::List/;

##############################################################################
### Overrides ################################################################
##############################################################################

sub tag_type { "itemList" }
sub list_class { 'Remedy::CMDB::Item' }

1;
