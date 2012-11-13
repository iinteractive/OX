package OX::Meta::Mount::Class;
use Moose;

extends 'OX::Meta::Mount';

has class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has dependencies => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
