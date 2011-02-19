package OX::Router;
use Moose;

use OX::Router::Route;

extends 'Path::Router';

has '+route_class' => (default => 'OX::Router::Route');

__PACKAGE__->meta->make_immutable;
no Moose;

1;
