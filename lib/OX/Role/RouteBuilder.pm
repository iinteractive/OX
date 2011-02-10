package OX::Role::RouteBuilder;
use Moose::Role;
use Bread::Board;

has 'route_builder_class' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'OX::Application::RouteBuilder::ControllerAction',
);

after BUILD => sub {
    my $self = shift;

    container $self->fetch('Router') => as {

        service 'builder' => (
            class      => $self->route_builder_class,
            parameters => {
                path       => { isa => 'Str'                   },
                route_spec => { isa => 'HashRef'               },
                service    => { isa => 'Bread::Board::Service' },
            }
        );

    };
};

sub configure_router {
    my ($self, $s, $router) = @_;

    if ($s->parent->has_service('config')) {
        my $service = $s->parent->get_service('config');
        my $routes  = $service->get;

        foreach my $path ( keys %$routes ) {

            ($s->parent->has_service('builder'))
                || confess "You must define a builder service in order to use the Router config";

            map {
                $router->add_route( @$_ )
            } $s->parent->get_service('builder')->get(
                path       => $path,
                route_spec => $routes->{ $path },
                service    => $service,
            )->compile_routes;
        }
    }
}

no Bread::Board;
no Moose::Role;

1;
