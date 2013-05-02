package OX::Application::Role::Router;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: base role for applications with routers

use Bread::Board;
use Class::Load 'load_class';
use Scalar::Util 'weaken';

=head1 DESCRIPTION

This is an abstract role for creating applications based on a router. You
probably want to use L<OX::Application::Role::Router::Path::Router> instead,
unless you need to use a different router.

This role adds a C<Router> service to the application container, which can be
configured by the C<build_router> and C<router_dependencies> methods. It also
overrides C<build_app> to automatically build a L<PSGI> application from the
routes in the router.

This role also defines the C<ox.router> key in the PSGI environment, so that
the application code and middleware can easily access the router.

=cut

=method router_class

Required method which should return the class name which the router object
itself will be an instance of.

=method app_from_router

Required method which should take a router instance and return a L<PSGI>
application coderef.

=cut

requires qw(router_class app_from_router);

sub BUILD { }
before BUILD => sub {
    my $_self = shift;
    weaken(my $self = $_self);

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

This method returns the router instance that is in use. It is equivalent to
C<< $app->resolve(service => 'Router') >>.

=cut

sub router { shift->resolve(service => 'Router') }

=method build_router($service)

This method is called by the C<Router> service to create a new router instance.
By default, it calls C<new> on the specified C<router_class>. It is passed the
C<Router> service object, so that you can access the resolved dependencies you
specify in C<router_dependencies>.

=cut

sub build_router {
    my $self = shift;
    my ($s) = @_;
    my $router_class = $self->router_class;
    load_class($router_class);
    return $router_class->new(%{ $s->params });
}

=method configure_router($router)

This method is called after a new router is instantiated, to allow you to add
routes to the router (or do whatever other configuration is necessary).

=cut

sub configure_router { }

=method router_dependencies

This method returns a hashref of dependencies, as described in L<Bread::Board>.
The arrayref form of dependency specification is not currently supported. These
dependencies can be accessed in the C<build_router> method.

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
