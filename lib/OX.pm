package OX;
use Moose::Exporter;

use Bread::Board ();
use Bread::Board::Declare ();
use Scalar::Util qw(blessed);

use Bread::Board::LifeCycle::Request;

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose', 'Bread::Board::Declare'],
    with_meta => [qw(router route mount wrap xo)],
    as_is     => [qw(service as)],
    install => [qw(import unimport)],
    class_metaroles => {
        class => ['OX::Meta::Role::Class',
                  'OX::Meta::Role::Class::RouteBuilder'],
    },
    base_class_roles => [
        'OX::Role::Object',
        'OX::Role::RouteBuilder',
        'OX::Role::Path::Router',
    ],
);

sub init_meta {
    my $package = shift;
    my %options = @_;
    $options{base_class} = 'OX::Application';
    Moose->init_meta(%options);
    $package->$init_meta(%options);
}

{
    my $anon = 0;
    sub service {
        my $name = '__ANON__:' . $anon++;
        local $Bread::Board::CC = Bread::Board::Container->new(name => $name);
        return Bread::Board::service($name, @_);
    }
}

sub as (&) { $_[0] }

sub _fix_router_dependencies {
    my ($router_service) = @_;
    for my $dep_name (keys %{ $router_service->dependencies }) {
        my $dep = $router_service->get_dependency($dep_name);
        if ($dep->has_service_path && $dep->service_path !~ m+^/+) {
            $router_service->add_dependency(
                $dep_name => $dep->clone(
                    service_path => '../' . $dep->service_path,
                )
            );
        }
    }
}

sub router {
    my $meta = shift;

    if (ref($_[0]) eq 'ARRAY') {
        $meta->add_route_builder($_) for @{ $_[0] };
        shift;
    }

    my ($body, %params) = @_;

    if (!ref($body)) {
        Class::MOP::load_class($body);
        my $service = Bread::Board::ConstructorInjection->new(
            name         => 'router',
            class        => $body,
            dependencies => \%params,
        );
        _fix_router_dependencies($service);
        $meta->router($service);
    }
    elsif (ref($body) eq 'CODE') {
        Carp::confess "only one top level router is allowed"
            if $meta->has_local_router_config;

        $meta->add_route_builder('OX::RouteBuilder::ControllerAction');
        $meta->add_route_builder('OX::RouteBuilder::Code');

        $body->();

        my $routes = $meta->routes;
        my $router_config = Bread::Board::BlockInjection->new(
            name         => 'config',
            block        => sub { $routes },
            dependencies => \%params,
        );
        _fix_router_dependencies($router_config);
        $meta->router_config($router_config);
    }
    elsif (blessed($body)) {
        my $service = Bread::Board::Literal->new(
            name  => 'router',
            value => $body,
        );
        $meta->router($service);
    }
    else {
        Carp::confess "Unknown argument to 'router': $body";
    }
}

sub route {
    my ($meta, $path, $action_spec, %params) = @_;

    my ($class, $route_spec) = $meta->route_builder_for($action_spec);
    $meta->add_route($path => {
        class      => $class,
        route_spec => $route_spec,
        params     => \%params,
    });
}

sub mount {
    my ($meta, $path, $mount, %params) = @_;

    if (ref($mount) eq 'CODE') {
        $meta->add_mount($path => {
            app => $mount,
        });
    }
    elsif (!ref($mount)) {
        Class::MOP::load_class($mount);
        die "Class $mount doesn't implement a to_app method"
            unless $mount->can('to_app');

        $meta->add_mount($path => {
            class        => $mount,
            dependencies => \%params,
        });
    }
    else {
        die "Unknown mount $mount";
    }
}

sub wrap {
    my $meta = shift;
    $meta->add_middleware($_[0]);
}

sub xo {
    my $meta = shift;
    $meta->new_object->to_app;
}

1;

__END__

=pod

=head1 NAME

OX - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX;

  router as {
      route '/' => sub { "Hello world" };
  };

  xo;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
