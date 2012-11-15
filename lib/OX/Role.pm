package OX::Role;
use Moose::Exporter;
use 5.010;
# ABSTRACT: declare roles for your OX applications

use Bread::Board::Declare 0.11 ();
use Carp 'confess';
use namespace::autoclean ();
use Scalar::Util 'blessed';

use OX ();

=head1 SYNOPSIS

  package MyApp::Role::Auth;
  use OX::Role;

  has auth => (
      is  => 'ro',
      isa => 'MyApp::Auth',
  );

  router as {
      route '/auth/login'  => 'auth.login';
      route '/auth/logout' => 'auth.logout';
  };

  package MyApp;
  use OX;

  with 'MyApp::Role::Auth';

  has root => (
      is  => 'ro',
      isa => 'MyApp::Controller::Root',
  );

  router as {
      route '/' => 'root.index';
  };

=head1 DESCRIPTION

This module allows you to define roles to be applied to your L<OX>
applications. OX roles can define any part of the application that an OX class
can, except for middleware and declaring a pre-built router or router class.
When you consume the role, all of the services, routes, and mounts will be
composed into the application class.

During composition, conflicts between mounts and routes will be checked for,
similar to how roles normally detect conflicts between methods and attributes.
If two mounts are declared with the same path, a conflict will be generated,
and if two routes are declared with the same path (disregarding the names of
variable path components), a conflict will also be generated. The consuming
class can resolve these types of conflicts by declaring its own mount or route,
respectively. If a route is declared which would be shadowed by a mount
declared in another role, this generates an unresolvable conflict - you'll need
to fix this in the roles themselves.

Note that since the router keyword doesn't happen at compile time, you should
most likely put the C<with> statement for your application roles after the
C<router> block.

=cut

my ($import) = Moose::Exporter->build_import_methods(
    also      => ['Moose::Role', 'Bread::Board::Declare'],
    with_meta => [qw(router)],
    as_is     => [\&OX::route, \&OX::mount, \&OX::as, \&OX::literal],
    install   => [qw(unimport init_meta)],
    role_metaroles => {
        role                    => ['OX::Meta::Role::Role'],
        application_to_class    => ['OX::Meta::Role::Application::ToClass'],
        application_to_role     => ['OX::Meta::Role::Application::ToRole'],
        application_to_instance => ['OX::Meta::Role::Application::ToInstance'],
    },
);

sub import {
    my ($package, $args) = @_;
    my $into = $args && $args->{into} ? $args->{into} : caller;
    namespace::autoclean->import(-cleanee => $into);
    goto $import;
}

=func as

  router as {
      ...
  };

Sugar function for declaring coderefs.

=cut

=func router

  router as {
      ...
  };

This function declares the router for your application. By default, it creates
a router based on L<Path::Router>. Within the C<router> body, you can declare
routes, middleware, and mounted applications using the C<route>, C<wrap>, and
C<mount> keywords described below.

  router ['My::Custom::RouteBuilder'] => as {
      ...
  };

By default, actions specified with C<route> will be parsed by either
L<OX::RouteBuilder::ControllerAction>, L<OX::RouteBuilder::HTTPMethod>, or
L<OX::RouteBuilder::Code>, whichever one matches the route. If you want to be
able to specify routes in other ways, you can specify a list of
L<OX::RouteBuilder> classes as the first argument to C<router>, which will be
used in place of the previously mentioned list.

=cut

sub router {
    my ($meta, @args) = @_;
    confess "Only one top level router is allowed"
        if $meta->has_route_builders;

    if (ref($args[0]) eq 'ARRAY') {
        $meta->add_route_builder($_) for @{ $args[0] };
        shift @args;
    }
    my ($body) = @args;

    if (ref($body) eq 'CODE') {
        if (!$meta->has_route_builders) {
            $meta->add_route_builder('OX::RouteBuilder::ControllerAction');
            $meta->add_route_builder('OX::RouteBuilder::HTTPMethod');
            $meta->add_route_builder('OX::RouteBuilder::Code');
        }

        local $OX::CURRENT_CLASS = $meta;
        $body->();
    }
    else {
        confess "Roles only support the block form of 'router', not $body";
    }
}

=func route $path, $action_spec, %params

The C<route> keyword adds a route to the current router. It is only valid in a
C<router> block. The first parameter to C<route> is the path for the route to
match, the second is an C<action_spec> to be parsed by an L<OX::RouteBuilder>
class, and the remaining parameters are a hash of parameters containing either
defaults or validations for the router to use when matching.

  route '/' => 'controller.index';

This declares a simple route using the L<OX::RouteBuilder::ControllerAction>
route builder. When the application receives a request for C</>, the
application will resolve the C<controller> service, and call the C<index>
method on it, passing in an L<OX::Request> instance for the request. The
C<index> method should return either a string, a L<PSGI> response arrayref, or
an object that responds to C<finalize> (probably a L<Web::Response> object).

  route '/view/:id' => 'posts.view', (
      id   => { isa => 'Int' },
      name => 'view',
  );

This declares a route with parameters. This will resolve the C<posts> service
and call the C<view> method on it, passing in a request object and the value of
C<id>. If C<id> was provided but was not an C<Int>, this route will not match
at all. Inside the C<view> method, the C<mapping> method will return a hash of
C<< (controller => 'posts', action => 'view', id => $id, name => 'view') >>.

Also, other parts of the application can call C<uri_for> with any unique subset
of those parameters (such as C<< (name => 'view', id => 1) >>) to get the
absolute URL path for this route (for instance, C<"/myapp/view/1"> if this app
is mounted at C</myapp>).

  route '/method' => 'method_controller';

Since this action spec doesn't contain a C<.>, this will be handled by the
L<OX::RouteBuilder::HTTPMethod> route builder. If a user sends a C<GET> request
to C</method>, it will resolve the C<method_controller> service, and call the
C<get> method on it, passing in the request object. Variable path components
and defaults and validations work identically to the description above.

  route '/get_path' => sub { my $r = shift; return $r->path };

This route will just call the given coderef directly, passing in the request
object. Variable path components and defaults and validations work identically
to the description above.

  route '/custom' => $my_custom_thing;

In addition, if you specified any custom route builders in the C<router>
description, you can pass anything that they can handle into the second
argument here as well.

=cut

=func mount

The C<mount> keyword declares an entirely separate application to be mounted
under a given path in your application's namespace. This is different from
C<route>, because the targets are full applications, which handle the entire
path namespace under the place they are mounted - they aren't just handlers for
one specific path.

  mount '/other_app' => 'My::Other::App', (
      template_root => 'template_root',
  );

If you specify a class name for the target, it will create an app by creating
an instance of the class (resolving the parameters as dependencies and passing
them into the constructor) and calling C<to_app> on that instance.

  mount '/other_app' => My::Other::App->new;

If you specify an object as the target, it will create the app by calling
C<to_app> on that object.

  mount '/other_app' => sub {
      my $env = shift;
      return [ 200, [], [$env->{PATH_INFO}] ];
  };

You can also specify a coderef directly. Note that in this case, unlike
specifying a coderef as the route spec for the C<route> keyword, the coderef is
a plain L<PSGI> application, which receives an env hashref and returns a full
PSGI response arrayref.

=cut

=func literal

  wrap 'Plack::Middleware::Static', (
      path => literal(qr{^/(images|js|css)/}),
      root => 'static_root',
  );

The C<literal> keyword allows you to declare dependencies on literal values,
rather than services. This is useful for situations where the constructor
values aren't user-configurable, but are inherent to your app's structure, such
as the C<path> option to L<Plack::Middleware::Static>, or the C<subrequest>
option to L<Plack::Middleware::ErrorDocument>.

=cut

=for Pod::Coverage
  import
  init_meta

=cut

1;
