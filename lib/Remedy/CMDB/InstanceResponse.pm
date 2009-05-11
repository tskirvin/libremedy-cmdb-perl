package Remedy::CMDB::InstanceResponse;
our $VERSION = "0.01.01";
# Copyright and license are in the documentation below.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

##############################################################################
### Configuration ############################################################
##############################################################################

##############################################################################
### Declarations #############################################################
##############################################################################

use strict;
use warnings;

use Remedy::CMDB::Struct qw/init_struct/;
our @ISA = init_struct (__PACKAGE__);

##############################################################################
### Subroutines ##############################################################
##############################################################################

=head1 FUNCTIONS

=over 4

=item fields ()

=cut

sub fields {
    'instanceid'  => 'Remedy::CMDB::Item::InstanceID',
    'text'        => '$',
    'alternateid' => '@',
}

=item populate_xml (XML)

=cut

sub populate_xml {
    my ($self, $xml) = @_;
    return 'no xml' unless ($xml && ref $xml);
    return 'tag type should be instanceResponse'
        unless ($xml->tag eq 'instanceResponse');

    $self->clear_object;

    my @items;
    if (my $declined = $xml->first_child ('declined')) {
        my @reasons;
        foreach ($declined->children ('reason')) {
            push @reasons, $_->text;
        }
        $self->reason (@reasons);
    }

    if (my $accept = $xml->first_child ('accepted')) {
        my @alternate;
        foreach my $item ($accept->children ('alternateInstanceId')) {
            my $obj = Remedy::CMDB::AlternateInstanceID->read ('xml',
                'source' => $item, 'type' => 'object');
            return 'no object created' unless $obj;
            return $obj unless ref $obj;
            my $id = $obj;
            push @alternate, $id;
        }
        $self->alternate (@alternate)
    }

    return 'cannot be both declined and accepted'
        if ($self->reason && $self->alternateid);
    return 'must be either declined or accepted'
        unless ($self->reason || $self->alternateid);

    {
        my $id;
        foreach my $item ($xml->children ('instanceId')) {
            return 'too many instanceIds' if $id;
            my $obj = Remedy::CMDB::Item::InstanceID->read ('xml',
                'source' => $item, 'type' => 'object');
            return 'no object created' unless $obj;
            return $obj unless ref $obj;
            $id = $obj;
        }
        $self->instanceid ($id);
        return "no instanceid" unless $self->instanceid;
    }

    return;
}

sub populate {
    my ($self, %args) = @_;
    return 'no id' unless my $id = $args{'id'};
    if (!ref $id && lc $id eq 'global') { 
        my $new = Remedy::CMDB::Item::InstanceID->new ();
        $new->mdrid ('GLOBAL');
        $new->localid ();
        $id = $new;        
    }
    my $type = $args{'type'} || 'default';
    if    ($type eq 'approved') { return $self->populate_approved (%args) }
    elsif ($type eq 'declined') { return $self->populate_declined (%args) }
    elsif ($type eq 'error')    { return $self->populate_error    (%args) }
    else                        { return "invalid type: $type" }
}

sub populate_declined {
    my ($self, %args) = @_; 
    $self->text ($args{'text'});
    return;
}

sub populate_success {
    my ($self, %args) = @_;
    return;
}

sub populate_error { 
    my ($self, %args) = @_;
    return;
}

sub clear_object {
    my ($self) = @_;
    $self->alternateid ([]);
    $self->instanceid  (undef);
    $self->text        (undef);
    return;
}

##############################################################################
### 
##############################################################################

sub tag_type { 'instanceResponse' }

sub text {
    my ($self) = @_;
    my @return;

    # [...]

    wantarray ? @return : join ("\n", @return, '');
}

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
