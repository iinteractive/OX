package OX;
use Moose::Exporter;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Bread::Board ();
use Scalar::Util qw(blessed);

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose'],
    with_meta => [qw(router component config)],
    as_is     => [
        'route',
        \&Bread::Board::depends_on,
        \&Bread::Board::as,
    ],
    install => [qw(import unimport)],
    class_metaroles => {
        class => ['OX::Meta::Role::Class'],
    },
    base_class_roles => ['OX::Role::Object'],
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
        die "A router must be a subclass of Path::Router, not $body"
            unless $body->isa('Path::Router');
        $meta->router($body->new);
    }
    elsif (ref($body) eq 'CODE') {
        die "only one top level router is allowed"
            if $meta->has_router_config;

        local $ROUTES = {};
        $body->();
        my $routes = $ROUTES;
        $meta->router_config(
            Bread::Board::BlockInjection->new(
                name         => 'router_config',
                block        => sub { $routes },
                dependencies => \%params,
            )
        );
    }
    elsif (blessed($body) && $body->isa('Path::Router')) {
        $meta->router($body);
    }
    else {
        die "Unknown argument to 'router': $body";
    }
}

sub route {
    my ($path, $action_spec, %params) = @_;

    my ($controller, $action) = split /\./, $action_spec;

    $ROUTES->{$path} = {
        controller => $controller,
        action     => $action,
        %params,
    };
}

sub component {
    my $meta = shift;

    my %args;

    if (@_ == 1 && ref($_[0]) eq 'HASH') {
        # component { name => 'TT', class => 'My::App::View', ... }
        %args = %{ $_[0] };
    }
    elsif ((@_ % 2) == 1) {
        # component 'My::App::View' => (...)
        my ($class, %deps) = @_;
        die "Must supply a name for block injection components"
            if ref($class);
        my $name = (split /::/, $class)[-1];
        %args = (
            name         => $name,
            class        => $class,
            %deps ? (dependencies => \%deps) : (),
        );
    }
    else {
        my ($name, $service_val, %deps) = @_;
        %args = (
            name => $name,
            %deps ? (dependencies => \%deps) : (),
        );
        if (!ref($service_val)) {
            # component 'TT' => 'My::App::View' => (...)
            $args{class} = $service_val;
        }
        elsif (ref($service_val) eq 'CODE') {
            # component 'TT' => sub { My::App::View->new }, (...)
            $args{block} = $service_val;
        }
        elsif (ref($service_val) eq 'HASH') {
            # component 'TT' => { class => 'My::App::View', ... }
            %args = (%args, %$service_val);
        }
        else {
            die 'XXX';
        }
    }

    Class::MOP::load_class($args{class})
        if exists $args{class};

    my $class = _service_class_from_args(%args);
    my $service = $class->new(%args);

    $meta->add_component($service);
}

sub config {
    my $meta = shift;
    my $name = shift;

    my %args;
    if (@_ == 1 && !ref($_[0])) {
        # config email => 'foo@example.com'
        my ($service_val) = @_;
        %args = (
            name  => $name,
            value => $service_val,
        );
    }
    elsif (@_ == 1 && ref($_[0]) eq 'HASH') {
        # config { name => 'email', ... }
        %args = %{ $_[0] };
    }
    elsif (@_ == 2 && !ref($_[0]) && ref($_[1]) eq 'HASH') {
        # config email => { ... }
        my ($name, $params) = @_;
        %args = (name => $name, %$params);
    }
    elsif ((@_ % 2) == 1) {
        # config id => sub { state $i++ }, (...)
        my ($service_val, %deps) = @_;
        die "config must be either a string or a coderef"
            unless ref($service_val) eq 'CODE';
        %args = (
            name  => $name,
            block => $service_val,
            %deps ? (dependencies => \%deps) : (),
        );
    }
    else {
        die "config must be either a string or a coderef";
    }

    Class::MOP::load_class($args{class})
        if exists $args{class};

    my $class = _service_class_from_args(%args);
    my $service = $class->new(%args);
    $meta->add_config($service);
}

sub _service_class_from_args {
    my %args = @_;

    die "Must provide a value"
        unless exists $args{class}
            || exists $args{value}
            || exists $args{block};

    return exists $args{class} ? "Bread::Board::ConstructorInjection"
         : exists $args{value} ? "Bread::Board::Literal"
         :                       "Bread::Board::BlockInjection";
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
