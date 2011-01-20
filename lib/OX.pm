package OX;
use Moose::Exporter;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Bread::Board ();

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose'],
    with_meta => [qw(route resource component config)],
    as_is     => [
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

sub route {
    my $meta = shift;
    my ($path, $action_spec, %params) = @_;

    my ($controller, $action) = split /\./, $action_spec;

    $meta->add_route(
        $path => {
            controller => $controller,
            action     => $action,
            %params,
        }
    );
}

sub resource {
    my $meta = shift;

    my ($name, $service_val, %params);

    if ((@_ % 2) == 1) {
        # resource 'My::App::Controller' => (...)
        ($service_val, %params) = @_;
        die 'XXX' if ref($service_val);
        $name = (split /::/, $service_val)[-1];
    }
    else {
        # resource 'Root' => 'My::App::Controller' => (...)
        # resource 'Root' => sub { My::App::Controller->new }, (...)
        ($name, $service_val, %params) = @_;
    }

    my $service;
    if (!ref($service_val)) {
        Class::MOP::load_class($service_val);
        $service = Bread::Board::ConstructorInjection->new(
            name         => $name,
            class        => $service_val,
            dependencies => \%params, # XXX: do something better here
        );
    }
    elsif (ref($service_val) eq 'CODE') {
        $service = Bread::Board::BlockInjection->new(
            name         => $name,
            block        => $service_val,
            dependencies => \%params, # XXX: do something better here
        );
    }

    $meta->add_resource($service);
}

# XXX: remove duplication
sub component {
    my $meta = shift;

    my ($name, $service_val, %params);

    if ((@_ % 2) == 1) {
        # component 'My::App::View' => (...)
        ($service_val, %params) = @_;
        die 'XXX' if ref($service_val);
        $name = (split /::/, $service_val)[-1];
    }
    else {
        # component 'TT' => 'My::App::View' => (...)
        # component 'TT' => sub { My::App::View->new }, (...)
        ($name, $service_val, %params) = @_;
    }

    my $service;
    if (!ref($service_val)) {
        Class::MOP::load_class($service_val);
        $service = Bread::Board::ConstructorInjection->new(
            name         => $name,
            class        => $service_val,
            dependencies => \%params, # XXX: do something better here
        );
    }
    elsif (ref($service_val) eq 'CODE') {
        $service = Bread::Board::BlockInjection->new(
            name         => $name,
            block        => $service_val,
            dependencies => \%params, # XXX: do something better here
        );
    }

    $meta->add_component($service);
}

sub config {
    my $meta = shift;
    my $name = shift;

    my $service;
    if (@_ == 1 && !ref($_[0])) {
        # config email => 'foo@example.com'
        my ($service_val) = @_;
        $service = Bread::Board::Literal->new(
            name  => $name,
            value => $service_val,
        );
    }
    elsif ((@_ % 2) == 1) {
        # config id => sub { state $i++ }, (...)
        my ($service_val, %params) = @_;
        die 'XXX' unless ref($service_val) eq 'CODE';
        $service = Bread::Board::BlockInjection->new(
            name         => $name,
            block        => $service_val,
            dependencies => \%params, # XXX: do something better here
        );
    }
    else {
        die 'XXX';
    }

    $meta->add_config($service);
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
