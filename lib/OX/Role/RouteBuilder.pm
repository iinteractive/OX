package OX::Role::RouteBuilder;
use Moose::Role;

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
            my $controller = delete $route->{controller};
            my $action     = delete $route->{action};

            $route = {
                class      => 'OX::RouteBuilder::ControllerAction',
                route_spec => {
                    controller => $controller,
                    action     => $action,
                },
                params     => $route,
            };
        }
        elsif (ref($route) eq 'CODE') {
            $route = {
                class      => 'OX::RouteBuilder::Code',
                route_spec => $route,
                params     => {},
            };
        }

        Class::MOP::load_class($route->{class});
        my $builder = $route->{class}->new(
            path       => $path,
            route_spec => $route->{route_spec},
            params     => $route->{params},
            service    => $service,
        );

        $router->add_route(@$_)
            for $builder->compile_routes;
    }
}

no Moose::Role;

1;
