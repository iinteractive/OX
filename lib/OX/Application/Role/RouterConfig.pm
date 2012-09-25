package OX::Application::Role::RouterConfig;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: adds some common shortcuts to route declarations from OX::Application::Role::RouteBuilder

with 'OX::Application::Role::RouteBuilder';

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  use Bread::Board;

  extends 'OX::Application';
  with 'OX::Application::Role::RouterConfig',
       'OX::Application::Role::Router::Path::Router';

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
                          controller => 'root',
                          action     => 'index',
                      },
                      '/foo' => sub { 'FOO' },
                  }
              },
          );
      };
  }

=head1 DESCRIPTION

This role overrides C<parse_route> in L<OX::Application::Role::RouteBuilder> to
provide some nicer syntax. If a value in your router config contains the
C<controller> and C<action> keys, it will extract those out and automatically
construct an L<OX::RouteBuilder::ControllerAction> for you. If the value is a
single coderef, it will automatically construct an L<OX::RouteBuilder::Code>
for you.

=cut

around parse_route => sub {
    my $orig = shift;
    my $self = shift;
    my ($path, $route) = @_;

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

    return $self->$orig($path, $route);
};

1;
