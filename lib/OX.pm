package OX;
use Moose::Exporter;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Bread::Board ();
use Scalar::Util qw(blessed);

use OX::Meta::Role::Attribute::Config;

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose'],
    with_meta => [qw(router route component config mount wrap xo)],
    as_is     => [
        \&Bread::Board::depends_on,
        \&Bread::Board::as,
    ],
    install => [qw(import unimport)],
    class_metaroles => {
        class => ['OX::Meta::Role::Class'],
    },
    base_class_roles => ['OX::Role::Object', 'OX::Role::RouteBuilder'],
);

sub init_meta {
    my $package = shift;
    my %options = @_;
    $options{base_class} = 'OX::Application';
    Moose->init_meta(%options);
    $package->$init_meta(%options);
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
        Carp::confess "A router must be a subclass of Path::Router, not $body"
            unless $body->isa('Path::Router');
        $meta->router($body->new);
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
        for my $dep_name (keys %{ $router_config->dependencies }) {
            my $dep = $router_config->get_dependency($dep_name);
            if ($dep->has_service_path && $dep->service_path !~ m+^/+) {
                $router_config->add_dependency(
                    $dep_name => $dep->clone(
                        service_path => '../' . $dep->service_path,
                    )
                );
            }
        }
        $meta->router_config($router_config);
    }
    elsif (blessed($body) && $body->isa('Path::Router')) {
        $meta->router($body);
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

sub component {
    my $meta = shift;

    my $service = _parse_service_sugar('class', @_);
    $meta->add_component($service);
    return $service;
}

sub config {
    my $meta = shift;

    my $service = _parse_service_sugar('value', @_);
    $meta->add_config($service);
    return $service;
}

sub _parse_service_sugar {
    my ($bare_string) = shift;

    my %args;

    if (@_ >= 1 && !ref($_[0])) {
        $args{name} = shift;
    }

    if (@_ >= 1) {
        if (!ref($_[0])) {
            $args{$bare_string} = shift;
        }
        elsif (ref($_[0]) eq 'CODE') {
            $args{block} = shift;
        }
        elsif (ref($_[0]) ne 'HASH') {
            Carp::confess "Value given must be a string or coderef, not $_[0]";
        }
    }

    if (@_ == 1 && ref($_[0]) eq 'HASH') {
        %args = (%args, %{ $_[0] });
    }
    elsif ((@_ % 2) == 0) {
        %args = (%args, (@_ > 0) ? (dependencies => { @_ }) : ());
    }

    Class::MOP::load_class($args{class})
        if exists $args{class};

    my $class = _service_class_from_args(%args);
    return $class->new(%args);
}

sub _service_class_from_args {
    my %args = @_;

    Carp::confess "Must provide a value"
        unless exists $args{class}
            || exists $args{value}
            || exists $args{block};

    return exists $args{class} ? "Bread::Board::ConstructorInjection"
         : exists $args{value} ? "Bread::Board::Literal"
         :                       "Bread::Board::BlockInjection";
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
