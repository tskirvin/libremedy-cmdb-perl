package Remedy::CMDB::Item::InstanceID;



sub mdrid {}
sub localid {}

sub id {
    my ($self) = @_;
    return join ('@', $self->localid, $self->mdrid);
}

1;
