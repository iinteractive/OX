package OX::Application;
use Moose;
use Bread::Board::Declare;

use Bread::Board;
use Moose::Util::TypeConstraints
    qw(class_type subtype where match_on_type), as => { -as => 'mutc_as' };

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has _app => (
    is  => 'rw',
    isa => 'CodeRef'
);

class_type('Plack::Middleware');
subtype 'OX::Types::MiddlewareClass',
        mutc_as 'Str',
        where { Class::MOP::load_class($_); $_->isa('Plack::Middleware') };
subtype 'OX::Types::Middleware',
        mutc_as 'CodeRef|OX::Types::MiddlewareClass|Plack::Middleware';

has middleware => (
    traits  => ['Array'],
    isa     => 'ArrayRef[OX::Types::Middleware]',
    default => sub { [] },
    handles => {
        middleware => 'elements',
    },
);

sub router_class { 'OX::Router' }

sub BUILD {
    my $self = shift;
    container $self => as {

        container 'Router' => as {

            service 'router' => (
                block => sub {
                    my $s      = shift;
                    my $router_class = $self->router_class;
                    Class::MOP::load_class($router_class);
                    my $router = $router_class->new;
                    $self->configure_router( $s, $router );
                    $router;
                },
                dependencies => $self->router_dependencies
            );

        };

        service App => (
            block        => sub {
                my $s = shift;

                my $app = $self->app_from_router($s->param('router'));

                for my $middleware ($self->middleware) {
                    match_on_type $middleware => (
                        'CodeRef' => sub {
                            $app = $middleware->($app);
                        },
                        'OX::Types::MiddlewareClass' => sub {
                            $app = $middleware->wrap($app);
                        },
                        'Plack::Middleware' => sub {
                            $app = $middleware->wrap($app);
                        },
                        sub {
                            warn "not applying $middleware!";
                        },
                    );
                }

                return $app;
            },
            dependencies => ['Router/router'],
        );

    };
}

sub router_dependencies { [] }
sub configure_router { }
sub app_from_router {
    my $self = shift;
    my ($router) = @_;

    require Plack::App::Path::Router::PSGI;
    return Plack::App::Path::Router::PSGI->new(
        router => $router,
    )->to_app;
}

# can't use 'router', since that's used as a keyword
sub get_router { shift->resolve(service => 'Router/router') }

# ... Plack::Component API

sub prepare_app {
    my $self = shift;
    $self->_app( $self->resolve(service => 'App') );
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
    Bread::Board::Dumper->new->dump(shift());
}

no Moose; no Bread::Board; no Moose::Util::TypeConstraints; 1;

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
