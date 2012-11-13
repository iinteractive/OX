package OX::Meta::Mount::App;
use Moose;

extends 'OX::Meta::Mount';

has app => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
