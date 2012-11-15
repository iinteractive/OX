package OX;
use Moose::Exporter;
use 5.010;
# ABSTRACT: the hardest working two letters in Perl

use Bread::Board::Declare 0.11 ();
use Carp 'confess';
use Class::Load 0.10 'load_class';
use Moose::Util 'find_meta';
use namespace::autoclean ();
use Scalar::Util 'blessed';

=head1 SYNOPSIS

The following describes the outline of how a model-view-controller application
might be configured as an OX application.

  package MyApp;
  use OX;

  has model => (
      is        => 'ro',
      isa       => 'MyApp::Model',
      lifecycle => 'Singleton',
  );

  has template_root => (
      is     => 'ro',
      isa    => 'Str',
      value  => 'root',
  );

  has view => (
      is           => 'ro',
      isa          => 'Template',
      dependencies => {
          INCLUDE_PATH => 'template_root'
      },
  );

  has root => (
      is    => 'ro',
      isa   => 'MyApp::Controller',
      infer => 1,
  );

  router as {
      route '/'            => 'root.index';
      route '/inc'         => 'root.inc';
      route '/dec'         => 'root.dec';
      route '/reset'       => 'root.reset';
      route '/set/:number' => 'root.set' => (
          number => { isa => 'Int' },
      );
  };

=head1 DESCRIPTION

OX is a web application framework based on L<Bread::Board>, L<Path::Router>,
and L<PSGI>. Bread::Board lets you build your application from a collection of
normal L<Moose> objects, organized together in a "container", which allows
components to easily interoperate without any additional configuration.
Path::Router maps incoming request paths to method calls on the objects in the
Bread::Board container. Finally, at compile time, the framework turns your
entire application into a simple PSGI coderef, which can be used directly by
any PSGI-supporting web server.

The philosophy behind OX is that the building blocks of your web application
should just "click" together, without the overhead of an additional plugin
system or "glue" layer. The combination of Bread::Board, Path::Router, and the
Moose object system provides all that is needed for requests to be mapped to
methods and for components to communicate with each other. For example, all
configuration information can be provided via roles applied to the application
class (affecting application initialization). Similarly, additional runtime
features can be added by providing your own request (sub)class.

Additionally, OX provides an easy-to-use "sugar" layer (based on
L<Bread::Board::Declare>) that makes writing a web application as easy as
writing any Moose class. The OX sugar layer supports the full complement of
Moose features (attributes, roles, and more), as well as addiitonal sugar
methods for mapping request routes to object methods. (See
L<Bread::Board::Declare>, L<OX::Application::Role::Router::Path::Router>, and
L<OX::Application::Role::RouteBuilder> for more detailed information.) You're
also free to eschew the sugary syntax and build your application manually --
see L<OX::Application> for more information on going that route.

=cut

my ($import, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose', 'Bread::Board::Declare'],
    with_meta => [qw(router)],
    as_is     => [qw(route mount wrap wrap_if as literal)],
    install   => [qw(unimport)],
    class_metaroles => {
        class => ['OX::Meta::Role::Class'],
    },
    base_class_roles => [
        'OX::Application::Role::Router::Path::Router',
        'OX::Application::Role::RouteBuilder',
        'OX::Application::Role::Sugar',
    ],
);

sub import {
    my ($package, $args) = @_;
    my $into = $args && $args->{into} ? $args->{into} : caller;
    namespace::autoclean->import(-cleanee => $into);
    goto $import;
}

sub init_meta {
    my $package = shift;
    my %options = @_;
    $options{base_class} = 'OX::Application';
    Moose->init_meta(%options);
    $package->$init_meta(%options);
}

=func as

  router as {
      ...
  };

Sugar function for declaring coderefs.

=cut

sub as (&) { $_[0] }

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

  router 'My::Custom::Router' => (
      foo => 'some_service',
  );

  router(My::Custom::Router->new(%router_args));

If you have declared a router manually elsewhere, you can pass in either the
class name or the built router object to C<router> instead of a block. It will
be used directly in that case. If you pass a class name, it can take an
optional hash of dependencies, which will be resolved and passed into the
class's constructor as arguments. Note that parentheses are required if the
argument is a literal constructor call, to avoid it being parsed as an indirect
method call.

=cut

our $CURRENT_CLASS;

sub router {
    my ($top_meta, @args) = @_;

    my $meta = $CURRENT_CLASS
        ? _new_router_meta($CURRENT_CLASS)
        : $top_meta;

    confess "Only one top level router is allowed"
        if !$CURRENT_CLASS && $meta->has_route_builders;

    if (ref($args[0]) eq 'ARRAY') {
        $meta->add_route_builder($_) for @{ $args[0] };
        shift @args;
    }
    my ($body, %params) = @args;

    if (!ref($body)) {
        load_class($body);
        $meta->add_method(router_class        => sub { $body });
        $meta->add_method(router_dependencies => sub { \%params });
    }
    elsif (blessed($body)) {
        $meta->add_method(build_router => sub { $body });
    }
    elsif (ref($body) eq 'CODE') {
        if (!$meta->has_route_builders) {
            if ($CURRENT_CLASS) {
                for my $route_builder ($CURRENT_CLASS->route_builders) {
                    $meta->add_route_builder($route_builder);
                }
            }
            else {
                $meta->add_route_builder('OX::RouteBuilder::ControllerAction');
                $meta->add_route_builder('OX::RouteBuilder::HTTPMethod');
                $meta->add_route_builder('OX::RouteBuilder::Code');
            }
        }

        local $CURRENT_CLASS = $meta;
        $body->();
    }
    else {
        confess "Unknown argument to 'router': $body";
    }

    if (defined wantarray) {
        return $meta->new_object->to_app;
    }
}

sub _new_router_meta {
    my ($meta) = @_;

    return find_meta($meta)->name->create_anon_class(
        superclasses    => [$meta->name],
        routes          => [],
        mounts          => [],
        mixed_conflicts => [],
        middleware      => [],
        route_builders  => [],
    );
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

sub route {
    my ($path, $action_spec, %params) = @_;

    confess "route called outside of a router block"
        unless $CURRENT_CLASS;

    my ($class, $route_spec) = $CURRENT_CLASS->route_builder_for($action_spec);
    $CURRENT_CLASS->add_route(
        path                => $path,
        class               => $class,
        route_spec          => $route_spec,
        params              => \%params,
        definition_location => $CURRENT_CLASS->name,
    );
}

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

sub mount {
    my ($path, $mount, %deps) = @_;

    confess "mount called outside of a router block"
        unless $CURRENT_CLASS;

    my %default = (
        path                => $path,
        definition_location => $CURRENT_CLASS->name,
    );

    my %extra;
    if (!ref($mount)) {
        %extra = (
            class        => $mount,
            dependencies => \%deps,
        );
    }
    elsif (blessed($mount)) {
        %extra = (
            app => $mount->to_app,
        );
    }
    elsif (ref($mount) eq 'CODE') {
        %extra = (
            app => $mount,
        )
    }
    else {
        confess "Unknown mount $mount";
    }

    $CURRENT_CLASS->add_mount(%default, %extra);
}

=func wrap

The C<wrap> keyword declares a middleware to apply to the application. The
C<wrap> statements will be applied in order such that the first C<wrap>
statement corresponds to the outermost middleware (just like
L<Plack::Builder>).

  wrap 'Plack::Middleware::Static' => (
      path => literal(sub { s{^/static/}{} }),
      root => 'static_root',
  );

If you specify a class name as the middleware to apply, it will create an
instance of the class (resolving the parameters as dependencies and passing
them into the constructor) and call C<wrap> on that instance, passing in the
application coderef so far and using the result as the new application (this is
the API provided by L<Plack::Middleware>).

  wrap(Plack::Middleware::StackTrace->new(force => 1));

If you specify an object as the middleware, it will call C<wrap> on that
object, passing in the application coderef so far and use the result as the new
application. Note that parentheses are required if the argument is a literal
constructor call, to avoid it being parsed as an indirect method call.

  wrap sub {
      my $app = shift;
      return sub {
          my $env = shift;
          return [302, [Location => '/'], []]
              if $env->{PATH_INFO} eq '/';
          return $app->($env);
      };
  };

If you specify a coderef as the middleware, it will call that coderef, passing
in the application coderef so far, and use the result as the new application.

=cut

sub wrap {
    my ($middleware, %deps) = @_;

    confess "wrap called outside of a router block"
        unless $CURRENT_CLASS;

    $CURRENT_CLASS->add_middleware(
        middleware   => $middleware,
        dependencies => \%deps,
    );
}

=func wrap_if

C<wrap_if> works identically to C<wrap>, except that it requires an additional
initial coderef parameter for the condition under which this middleware should
be applied. This condition will be run on every request, and will receive the
C<$env> hashref as a parameter, so the condition can depend on variables in the
environment. For instance:

  wrap_if sub { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' },
      'Plack::Middleware::StackTrace' => (
          force => literal(1),
      );

=cut

sub wrap_if {
    my ($condition, $middleware, %deps) = @_;

    confess "wrap_if called outside of a router block"
        unless $CURRENT_CLASS;

    $CURRENT_CLASS->add_middleware(
        condition    => $condition,
        middleware   => $middleware,
        dependencies => \%deps,
    );
}

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

sub literal {
    my ($value) = @_;
    return Bread::Board::Literal->new(
        name  => '__ANON__',
        value => $value,
    );
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-ox at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OX>.

=head1 SEE ALSO

=head1 SUPPORT

The IRC channel for this project is C<#ox> on C<irc.perl.org>.

You can find this documentation for this module with the perldoc command.

    perldoc OX

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OX>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OX>

=item * Search CPAN

L<http://search.cpan.org/dist/OX>

=back

=for Pod::Coverage
  import
  init_meta

=cut

1;
