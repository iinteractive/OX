package OX::Application::Role::Router;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: base role for applications with routers

use Bread::Board;
use Class::Load 'load_class';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=method router_class

=method app_from_router

=cut

requires qw(router_class app_from_router);

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

=method router

=cut

sub router { shift->resolve(service => 'Router') }

=method build_router

=cut

sub build_router {
    my $self = shift;
    my ($s) = @_;
    my $router_class = $self->router_class;
    load_class($router_class);
    return $router_class->new(%{ $s->params });
}

=method configure_router

=cut

sub configure_router { }

=method router_dependencies

=cut

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
                # not just using plack.router (set by Plack::App::Path::Router)
                # because we want this to be accessible to user middleware
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

=pod

=for Pod::Coverage
  BUILD
  build_app

=cut

1;
