package OX::Meta::Role::Application::ToInstance;
use Moose::Role;
use namespace::autoclean;

use Moose::Util 'find_meta';

with 'OX::Meta::Role::Application';

sub _apply_routes {
    my $self = shift;
    my ($role, $obj) = @_;

    my $class = find_meta($obj);

    for my $route ($role->routes) {
        $class->_add_route($route)
            unless $class->has_route_for($route->{path});
    }

    $obj->regenerate_router_config;
}

no Moose::Role;

1;
