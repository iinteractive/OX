package OX::Role::RouteBuilder;
use Moose::Role;
use Bread::Board;

sub configure_router {
    my ($self, $s, $router) = @_;

    return unless $s->parent->has_service('config');

    my $service = $s->parent->get_service('config');
    my $routes  = $service->get;

    foreach my $path ( keys %$routes ) {
        my $route = $routes->{$path};
        # backcompat, and convenience sugar if people are working at a
        # lower level
        if (ref($route) eq 'HASH'
            && exists($route->{controller})
            && exists($route->{action})) {
            $route = {
                class      => 'OX::Application::RouteBuilder::ControllerAction',
                route_spec => $route,
            };
        }

        Class::MOP::load_class($route->{class});
        my $builder = $route->{class}->new(
            path       => $path,
            route_spec => $route->{route_spec},
            service    => $service,
        );

        $router->add_route(@$_)
            for $builder->compile_routes;
    }
}

no Bread::Board;
no Moose::Role;

1;
