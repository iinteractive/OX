package OX::Application::Role::RouteBuilder;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: application role to configure a router based on a static description

use Class::Load 'load_class';

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  use Bread::Board;
  extends 'OX::Application';
  with 'OX::Application::Role::RouteBuilder',
       'OX::Application::Role::Path::Router';

  sub BUILD {
      my $self = shift;
      container $self => as {
          service root => (
              class => 'Foo::Root',
          );

          service 'RouterConfig' => (
              block => sub {
                  +{
                      '/' => {
                          class      => 'OX::RouteBuilder::ControllerAction',
                          route_spec => {
                              controller => 'root',
                              action     => 'index',
                          },
                          params     => {},
                      },
                      '/foo' => {
                          class      => 'OX::RouteBuilder::Code',
                          route_spec => sub { 'FOO' },
                          params     => {},
                      },
                  }
              },
          );
      };
  }

=head1 DESCRIPTION

NOTE: unless you are building new framework bits, you probably want to use
L<OX::Application::Role::RouterConfig> instead, which provides some nicer
syntax for some common route builders.

This role provides a C<RouterConfig> service for your application container,
which should contain a description of all of the routes your application will
be handling. This description must be a hashref, where the keys are paths and
the values are hashrefs with C<class>, C<route_spec>, and C<params> keys.
C<class> determines which L<OX::RouteBuilder> class to use to parse this route,
C<route_spec> is a description of the route itself, and C<params> provides a
hashref of extra data (for instance, with
L<OX::Application::Role::Router::Path::Router>, C<params> holds the
L<Path::Router> defaults and validations).

=cut

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

=method parse_route($path, $route)

This method takes a path and a route description as described above and returns
a new L<OX::RouteBuilder> instance which will handle creating the routes. By
default it creates an instance of C<< $route->{class} >>, passing in the
C<$path>, C<< $route->{route_spec} >>, and C<< $route->{params} >> as
arguments, but you can override this in your app to provide more features.

=cut

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
