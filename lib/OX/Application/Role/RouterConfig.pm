package OX::Application::Role::RouterConfig;
use Moose::Role;
use namespace::autoclean;

with 'OX::Application::Role::RouteBuilder';

around parse_route => sub {
    my $orig = shift;
    my $self = shift;
    my ($route) = @_;

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

    return $self->$orig($route);
};

1;
