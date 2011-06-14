package OX::Router::Path::Router;
use Moose;
use namespace::autoclean;

use OX::Router::Path::Router::Route;

extends 'Path::Router';

has '+route_class' => (default => 'OX::Router::Path::Router::Route');

has request_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    handles  => {
        new_request => 'new',
    },
);

sub BUILD {
    my $self = shift;
    Class::MOP::load_class($self->request_class);
}

__PACKAGE__->meta->make_immutable;

1;
