package OX::Meta::Mount::App;
use Moose;
use namespace::autoclean;

extends 'OX::Meta::Mount';

has app => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

=for Pod::Coverage

=cut

1;
