package OX::Application::Role::Router::Path::Router;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: implementation of OX::Application::Role::Router which uses Path::Router

use Plack::App::Path::Router::Custom 0.05;

with 'OX::Application::Role::Router', 'OX::Application::Role::Request';

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  extends 'OX::Application';
  with 'OX::Application::Role::Router::Path::Router';

  sub configure_router {
      my ($self, $router) = @_;

      $router->add_route('/',
          target => sub { "Hello world" }
      );
  }

=head1 DESCRIPTION

This role uses L<Path::Router> to provide a router for your application. It
uses L<OX::Application::Role::Router>, and overrides C<router_class> to be
C<Path::Router> and C<app_from_router> to create an app using
L<Plack::App::Path::Router::Custom>. It also uses
L<OX::Application::Role::Request> to allow the application code to use
L<OX::Request> instead of bare environment hashrefs.

See L<OX::Application::Role::RouterConfig> for a more convenient way to
implement C<configure_router>.

=cut

sub router_class { 'Path::Router' }

sub app_from_router {
    my $self = shift;
    my ($router) = @_;

    return Plack::App::Path::Router::Custom->new(
        router => $router,
        new_request => sub {
            $self->new_request(@_);
        },
        target_to_app => sub {
            my ($target) = @_;
            my $app = blessed($target) && $target->can('to_app')
                ? $target->to_app
                : $target;
            sub {
                my ($req, @args) = @_;
                @args = map { $req->_decode($_) } @args;
                $app->($req, @args);
            }
        },
        handle_response => sub {
            $self->handle_response(@_);
        },
    )->to_app;
}

=pod

=for Pod::Coverage
  router_class
  app_from_router

=cut

1;
