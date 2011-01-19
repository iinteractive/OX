package OX::Application;
use Moose;
use Bread::Board;

use Path::Class;
use Class::Inspector;

use Path::Router;
use Plack::App::Path::Router;

use OX::Web::Request;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Bread::Board::Container';

has '+name' => ( lazy => 1, default => sub { (shift)->meta->name } );

has '_app' => ( is => 'rw', isa => 'CodeRef' );

has 'route_builder_class' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'OX::Application::RouteBuilder::ControllerAction',
);

sub BUILD {
    my $self = shift;
    container $self => as {

        service 'app_root' => do {
            my $class = $self->meta->name;
            my $root  = file( Class::Inspector->resolved_filename( $class ) );
            # climb out of the lib/ directory
            $root = $root->parent foreach split /\:\:/ => $class;
            $root = $root->parent; # one last time for lib/
            $root;
        };

        service 'route_builder' => (
            class      => $self->route_builder_class,
            parameters => {
                path       => { isa => 'Str'                   },
                route_spec => { isa => 'HashRef'               },
                service    => { isa => 'Bread::Board::Service' },
            }
        );

        service 'Router' => (
            class => 'Path::Router',
            block => sub {
                my $s      = shift;
                my $router = Path::Router->new;
                $self->configure_router( $s, $router );
                $router;
            },
            dependencies => $self->router_dependencies
        );

    };
}

sub router_dependencies { [] }
sub configure_router {
    my ($self, $s, $router) = @_;

    if ($s->parent->has_service('router_config')) {

        my $service = $s->parent->get_service('router_config');
        my $routes  = $service->get;

        foreach my $path ( keys %$routes ) {

            ($s->parent->has_service('route_builder'))
                || confess "You must define a route_builder service in order to use the router_config";

            map {
                $router->add_route( @$_ )
            } $s->parent->get_service('route_builder')->get(
                path       => $path,
                route_spec => $routes->{ $path },
                service    => $service,
            )->compile_routes;
        }
    }
}

# ... Plack::Component API

sub prepare_app {
    my $self = shift;
    $self->_app(
        Plack::App::Path::Router->new(
            router        => $self->resolve( service => 'Router'),
            request_class => 'OX::Web::Request',
        )->to_app
    );
}

sub call {
    my ($self, $env) = @_;
    $self->_app->( $env );
}

sub to_app {
    my $self = shift;
    $self->prepare_app;
    return sub { $self->call( @_ ) };
}

# ... Private Utils

sub _dump_bread_board {
    require Bread::Board::Dumper;
    Bread::Board::Dumper->new->dump( (shift)->bread_board );
}

no Moose; no Bread::Board; 1;

__END__

=pod

=head1 NAME

OX::Application - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::Application;

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
