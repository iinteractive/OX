package OX;
use Moose::Exporter;
# ABSTRACT: powerful and flexible PSGI web framework

use Bread::Board::Declare 0.11 ();
use Carp 'confess';
use Class::Load 0.10 'load_class';
use namespace::autoclean ();
use Scalar::Util 'blessed';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

my ($import, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose', 'Bread::Board::Declare'],
    with_meta => [qw(router route mount wrap)],
    as_is     => [qw(as)],
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

=func as

=cut

sub as (&) { $_[0] }

=func router

=cut

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
            $meta->add_route_builder('OX::RouteBuilder::HTTPMethod');
            $meta->add_route_builder('OX::RouteBuilder::Code');
        }

        $body->();
    }
    else {
        confess "Unknown argument to 'router': $body";
    }
}

=func route

=cut

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

=func mount

=cut

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

=func wrap

=cut

sub wrap {
    my ($meta, $middleware, %deps) = @_;

    $meta->add_middleware(
        middleware => $middleware,
        deps       => \%deps,
    );
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-ox at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OX>.

=head1 SEE ALSO

=head1 SUPPORT

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
