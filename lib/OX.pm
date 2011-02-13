package OX;
use Moose::Exporter;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Bread::Board ();
use Scalar::Util qw(blessed);

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose'],
    with_meta => [qw(router component config mount xo)],
    as_is     => [
        'route',
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

our $ROUTES;

sub router {
    my $meta = shift;
    my ($body, %params) = @_;

    if (!ref($body)) {
        Class::MOP::load_class($body);
        Carp::confess "A router must be a subclass of Path::Router, not $body"
            unless $body->isa('Path::Router');
        $meta->router($body->new);
    }
    elsif (ref($body) eq 'CODE') {
        Carp::confess "only one top level router is allowed"
            if $meta->has_router_config;

        local $ROUTES = {};
        $body->();
        my $routes = $ROUTES;
        my $router_config = Bread::Board::BlockInjection->new(
            name         => 'config',
            block        => sub { $routes },
            dependencies => \%params,
        );
        for my $dep_name (keys %{ $router_config->dependencies }) {
            my $dep = $router_config->get_dependency($dep_name);
            if ($dep->service_path !~ m+^/+) {
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
    my ($path, $action_spec, %params) = @_;

    if (!ref($action_spec) && $action_spec =~ /\./) {
        my ($controller, $action) = split /\./, $action_spec;

        $ROUTES->{$path} = {
            class      => 'OX::Application::RouteBuilder::ControllerAction',
            route_spec => {
                controller => $controller,
                action     => $action,
            },
            params     => \%params,
        };
    }
    elsif (ref($action_spec) eq 'CODE') {
        $ROUTES->{$path} = {
            class      => 'OX::Application::RouteBuilder::Code',
            route_spec => $action_spec,
            params     => \%params,
        };
    }
    else {
        die "Unknown route spec $action_spec for $path";
    }
}

sub mount {
    my ($meta, $path, $class, %params) = @_;

    Class::MOP::load_class($class);
    die "Only subclasses of OX::Application can be mounted"
        unless $class->isa('OX::Application');

    $meta->add_mount($path => {
        class        => $class,
        dependencies => \%params,
    });
}

sub component {
    my $meta = shift;

    my $service = _parse_service_sugar('class', @_);
    $meta->add_component($service);
}

sub config {
    my $meta = shift;

    my $service = _parse_service_sugar('value', @_);
    $meta->add_config($service);
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
