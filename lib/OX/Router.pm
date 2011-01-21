package OX::Router;
use Moose;

extends 'Path::Router';

use OX::Router::Route;

has '+route_class' => (default => 'OX::Router::Route');

__PACKAGE__->meta->make_immutable;
no Moose;

1;
