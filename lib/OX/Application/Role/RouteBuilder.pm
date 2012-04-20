package OX::Application::Role::RouteBuilder;
use Moose::Role;
use namespace::autoclean;

use Class::Load 'load_class';

after configure_router => sub {
    my $self = shift;
    my ($router) = @_;

    my $service = $self->fetch('RouterConfig');
    return unless $service;

    my $routes = $service->get;

    for my $path (keys %$routes) {
        my $route = $routes->{$path};

        my $builder = $self->parse_route($path, $route);

        # XXX this shouldn't be depending on path::router's api
        for my $route ($builder->compile_routes($self)) {
            my $path = delete $route->{path};
            $router->add_route($path => %$route);
        }
    }
};

sub parse_route {
    my $self = shift;
    my ($path, $route) = @_;

    load_class($route->{class});

    return $route->{class}->new(
        path       => $path,
        route_spec => $route->{route_spec},
        params     => $route->{params},
    );
}

1;
