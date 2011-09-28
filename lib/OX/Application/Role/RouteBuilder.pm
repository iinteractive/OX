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

        my $builder = $self->parse_route($route);

        $router->add_compiled_route($_)
            for $builder->compile_routes($self);
    }
};

sub parse_route {
    my $self = shift;
    my ($route) = @_;

    load_class($route->{class});

    return $route->{class}->new(
        path       => $route->{path},
        route_spec => $route->{route_spec},
        params     => $route->{params},
    );
}

1;
