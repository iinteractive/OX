package OX;
use Moose::Exporter;
# ABSTRACT: blah

use Bread::Board::Declare ();
use Carp 'confess';
use Class::Load 'load_class';
use namespace::autoclean ();
use Scalar::Util 'blessed';

my ($import, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose', 'Bread::Board::Declare'],
    with_meta => [qw(router route mount wrap xo)],
    as_is     => [qw(service as)],
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
    namespace::autoclean->import(-cleanee => scalar(caller));
    goto $import;
}

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

sub router {
    my ($meta, @args) = @_;
    confess "Only one top level router is allowed"
        if $meta->has_route_builders;

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
            $meta->add_route_builder('OX::RouteBuilder::ControllerAction');
            $meta->add_route_builder('OX::RouteBuilder::Code');
        }

        $body->();
    }
    else {
        confess "Unknown argument to 'router': $body";
    }
}

sub route {
    my ($meta, $path, $action_spec, %params) = @_;

    my ($class, $route_spec) = $meta->route_builder_for($action_spec);
    $meta->add_route(
        path       => $path,
        class      => $class,
        route_spec => $route_spec,
        params     => \%params,
    );
}

sub mount {
    my ($meta, $path, $mount, %params) = @_;

    if (!ref($mount)) {
        $meta->add_mount(
            path         => $path,
            class        => $mount,
            dependencies => \%params,
        );
    }
    elsif (blessed($mount)) {
        confess "Class " . blessed($mount) . " must implement a to_app method"
            unless $mount->can('to_app');

        $meta->add_mount(
            path => $path,
            app  => $mount->to_app,
        );
    }
    elsif (ref($mount) eq 'CODE') {
        $meta->add_mount(
            path => $path,
            app  => $mount,
        )
    }
    else {
        confess "Unknown mount $mount";
    }
}

sub wrap {
    my ($meta, $middleware, %deps) = @_;

    $meta->add_middleware(
        middleware => $middleware,
        deps       => \%deps,
    );
}

sub xo {
    my ($meta) = @_;
    $meta->new_object->to_app;
}

1;
