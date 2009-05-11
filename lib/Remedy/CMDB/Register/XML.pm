package Remedy::CMDB::Register::XML;

use strict;
use warnings;

use Remedy::CMDB::Struct::XML;

our @ISA = qw/Remedy::CMDB::Register Remedy::CMDB::Struct::XML/;

sub populate {
    my ($self) = @_;
    1;
}

1;
