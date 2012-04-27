package OX::Application;
use Moose 2.0200;
use namespace::autoclean;

use Bread::Board;
use Moose::Util::TypeConstraints 'match_on_type';
use Plack::Middleware::HTTPExceptions;
use Plack::Util;
use Try::Tiny;

use OX::Types;

extends 'Bread::Board::Container';

has name => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->meta->name },
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

                # these middleware always need to be outside of any user
                # defined middleware, in order to maintain the guarantees that
                # ox itself provides.
                my @default_middleware = (
                    sub {
                        my ($app) = @_;

                        return sub {
                            my $env = shift;

                            my $res = $app->($env);

                            Plack::Util::response_cb(
                                $res,
                                sub {
                                    return sub {
                                        my $content = shift;

                                        # flush all services that are
                                        # request-scoped after the response is
                                        # returned
                                        $self->_flush_request_services
                                            unless defined $content;

                                        return $content;
                                    };
                                }
                            );

                            return $res;
                        };
                    },
                    Plack::Middleware::HTTPExceptions->new(rethrow => 1),
                );

                my @middleware = reverse (
                    @default_middleware,
                    @{ $s->param('Middleware') },
                );

                for my $middleware (@middleware) {
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

                $app;
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

sub to_app {
    my $self = shift;
    return $self->resolve(service => 'App');
}

sub _flush_request_services {
    my $self = shift;

    for my $service ($self->get_service_list) {
        my $injection = $self->get_service($service);
        if ($injection->does('Bread::Board::LifeCycle::Request')) {
            $injection->flush_instance;
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
