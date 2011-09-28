package OX::Application;
use Moose;
use namespace::autoclean;

use Bread::Board;
use Moose::Util::TypeConstraints 'match_on_type';
use Plack::Middleware::HTTPExceptions;
use Try::Tiny;

use OX::Types;

extends 'Bread::Board::Container', 'Plack::Component';

has request_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'OX::Request',
);

has _app => (
    traits  => ['Code'],
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub { shift->resolve(service => 'App') },
    handles => {
        _call_app => 'execute',
    },
);

sub BUILD {
    my $self = shift;

    container $self => as {
        service Middleware => (
            block => sub {
                my $s = shift;
                $self->build_middleware($s);
            },
            dependencies => $self->middleware_dependencies,
        );

        service App => (
            block => sub {
                my $s = shift;

                my $app = $self->build_app($s);
                my @middleware = (
                    Plack::Middleware::HTTPExceptions->new(rethrow => 1),
                    @{ $s->param('Middleware') },
                );

                for my $middleware (reverse @middleware) {
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
                            warn "not applying middleware $middleware!";
                        },
                    );
                }

                return $app;
            },
            dependencies => $self->app_dependencies,
        );
    };
}

sub build_middleware { [] }
sub middleware_dependencies { {} }

sub build_app {
    my $self = shift;
    confess(blessed($self) . " must implement the build_app method");
}
sub app_dependencies {
    return { Middleware => 'Middleware' };
}

sub call {
    my $self = shift;
    my ($env) = @_;

    return $self->_call_app($env);
}

__PACKAGE__->meta->make_immutable;

1;
