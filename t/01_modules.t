##############################################################################
### Configuration ############################################################
##############################################################################

use vars qw/@MODULES $SIZE/;

BEGIN { 
    our @MODULES = qw/ 
        Remedy::Form::CMDB_Clear
        Remedy::CMDB
        Remedy::CMDB::Log
        Remedy::CMDB::Relationship
        Remedy::CMDB::Register
        Remedy::CMDB::Config
        Remedy::CMDB::Item
        Remedy::CMDB::Item::Response
        Remedy::CMDB::Item::List
        Remedy::CMDB::Item::Record
        Remedy::CMDB::Item::InstanceID
        Remedy::CMDB::Item::AlternateInstanceID
        Remedy::CMDB::Relationship::Record
        Remedy::CMDB::Relationship::Response
        Remedy::CMDB::Relationship::Source
        Remedy::CMDB::Relationship::Target
        Remedy::CMDB::Relationship::List
        Remedy::CMDB::Relationship::InstanceId
        Remedy::CMDB::Query::Response
        Remedy::CMDB::Struct
        Remedy::CMDB::Query
        Remedy::CMDB::Template::ID
        Remedy::CMDB::Template::Record
        Remedy::CMDB::Template::List
        Remedy::CMDB::Template::Response::Global::DataSource
        Remedy::CMDB::Template::Response::Global::Response
        Remedy::CMDB::Template::Response::Global
        Remedy::CMDB::Template::Response
        Remedy::CMDB::Template::ResponseItem
        Remedy::CMDB::Register::Response
        Remedy::CMDB::Server
        Remedy::CMDB::Server::XML
        Remedy::CMDB::Server::Response
        Remedy::CMDB::Sources
        Remedy::CMDB::Client
        Remedy::CMDB::Classes
        XML::Writer::Raw
    /;
    our $SIZE = scalar @MODULES;
}

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Test::More tests => $SIZE;

##############################################################################
### Module Checks ############################################################
##############################################################################
# XX checks (varies by the size of @MODULES)

foreach (@MODULES) { use_ok ($_) }
