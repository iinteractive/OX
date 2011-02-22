package OX::Router::Path::Router;
use Moose;

use OX::Router::Path::Router::Route;

extends 'Path::Router';

has '+route_class' => (default => 'OX::Router::Path::Router::Route');

__PACKAGE__->meta->make_immutable;
no Moose;

1;
