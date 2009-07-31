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

use Remedy::CMDB::Item::AlternateInstanceID;

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
    # 'instanceId'  => 'Remedy::CMDB::Item::InstanceID',
    'instanceId'  => '$',
    'string'      => '$',
    'type'        => '$',
    'alternateId' => '@',
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
            push @reasons, $_->string;
        }
        $self->reason (@reasons);
    }

    if (my $accept = $xml->first_child ('accepted')) {
        my @alternate;
        foreach my $item ($accept->children ('alternateInstanceId')) {
            my $obj = Remedy::CMDB::Item::AlternateInstanceID->read ('xml',
                'source' => $item, 'type' => 'object');
            return 'no object created' unless $obj;
            return $obj unless ref $obj;
            my $id = $obj;
            push @alternate, $id;
        }
        $self->alternate (@alternate)
    }

    return 'cannot be both declined and accepted'
        if ($self->reason && $self->alternateId);
    return 'must be either declined or accepted'
        unless ($self->reason || $self->alternateId);

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
        $self->instanceId ($id);
        return "no instanceId" unless $self->instanceId;
    }

    return;
}

sub xml {
    my ($self, @args) = @_;

    my $string;
    my $writer = XML::Writer::Raw->new ('OUTPUT' => \$string, 
        'DATA_INDENT' => 4, 'NEWLINES' => 0, 'DATA_MODE' => 1, 
        'UNSAFE' => 1, @args);

    $writer->startTag ($self->tag_type);
    
    my $id = $self->instanceId;
    $writer->write_elem_or_raw ('instanceId', $self->instanceId);

    my $alternate = $self->alternateId;

    my $type = lc $self->type;
    if ($type eq 'accepted') { 
        $writer->startTag ('accepted');
        foreach (@$alternate) {
            $writer->write_elem_or_raw ('alternateInstanceId', $_);
        }
        $writer->dataElement ('notes', $self->string);
        # write out the alternateInstanceId
        $writer->endTag;
    } elsif ($type eq 'declined') {
        $writer->startTag ('declined');
        $writer->dataElement ('reason', $self->string);
        $writer->endTag;
    } elsif ($type eq 'error') { 
        $writer->startTag ('declined');
        $writer->dataElement ('reason', "ERROR: " . $self->string);
        $writer->endTag;
    } else {
        $writer->startTag ('declined');
        $writer->dataElement ('reason', "ERROR: invalid response type ($type)");
        $writer->endTag;
    }

    $writer->endTag;
    $writer->end;
    
    return $string;
}

sub populate {
    my ($self, %args) = @_;
    return 'no item' unless my $item = $args{'item'};

    my $id = ref $item ? $item->instanceId 
                       : 'GLOBAL';
    $self->instanceId ($id);

    my $type = $args{'type'} || 'default';
    if    ($type eq 'accepted') { return $self->populate_accepted (%args) }
    elsif ($type eq 'declined') { return $self->populate_declined (%args) }
    elsif ($type eq 'error')    { return $self->populate_error    (%args) }
    else                        { return "invalid type: $type" }
}

=item populate_accepted (ARGHASH)

=over 2

=item obj I<Remedy::CMDB::Item>

=item string I<STRING>

=cut

sub populate_accepted {
    my ($self, %args) = @_;
    $self->type ('accepted');
    if (my $obj = $args{'obj'}) {
        my $alternate = Remedy::CMDB::Item::AlternateInstanceID->new;
        $alternate->mdrId   ($obj->get ('DatasetId'));
        $alternate->localId ($obj->get ('InstanceId'));
        $self->alternateId (0, $alternate);
    }
    $self->string ($args{'string'});
    return;
}

sub populate_declined {
    my ($self, %args) = @_; 
    $self->type ('declined');
    $self->string ($args{'string'});
    return;
}

sub populate_error { 
    my ($self, %args) = @_;
    $self->type ('declined');
    $self->string ($args{'string'});
    return;
}

sub clear_object {
    my ($self) = @_;
    $self->alternateId ([]);
    $self->instanceId  (undef);
    $self->string      (undef);
    return;
}

##############################################################################
### 
##############################################################################

sub tag_type { 'instanceResponse' }

=back

=cut

##############################################################################
### Final Documentation ######################################################
##############################################################################

1;
