package OX::Application::Role::Router;
use Moose::Role;
use namespace::autoclean;

use Bread::Board;
use Class::Load 'load_class';

requires qw(router_class app_from_router request_class);

sub BUILD { }
before BUILD => sub {
    my $self = shift;

    container $self => as {
        service Router => (
            class => $self->router_class,
            block => sub {
                my $s = shift;
                my $router = $self->build_router($s);
                $self->configure_router($router);
                return $router;
            },
            dependencies => $self->router_dependencies,
        );
    };
};

sub router { shift->resolve(service => 'Router') }

sub build_router {
    my $self = shift;
    my ($s) = @_;
    my $router_class = $self->router_class;
    load_class($router_class);
    return $router_class->new(
        %{ $s->params },
        request_class => $self->request_class,
    );
}
sub configure_router { }
sub router_dependencies { {} }

around build_middleware => sub {
    my $orig = shift;
    my $self = shift;
    my ($s) = @_;

    my $router = $s->param('Router');

    return [
        sub {
            my $app = shift;
            return sub {
                my $env = shift;
                $env->{'ox.router'} = $router;
                $app->($env);
            }
        },
        @{ $self->$orig(@_) },
    ];
};
around middleware_dependencies => sub {
    my $orig = shift;
    my $self = shift;

    return {
        %{ $self->$orig(@_) },
        Router => 'Router',
    };
};

sub build_app {
    my $self = shift;
    my ($s) = @_;

    return $self->app_from_router($s->param('Router'));
}
around app_dependencies => sub {
    my $orig = shift;
    my $self = shift;
    return {
        %{ $self->$orig(@_) },
        Router => 'Router',
    };
};

1;
