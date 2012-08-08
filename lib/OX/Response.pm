package OX::Response;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'Plack::Response';

sub BUILDARGS {
    return {};
}

__PACKAGE__->meta->make_immutable;

1;
