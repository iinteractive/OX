package OX::Application;
use Moose;
use namespace::autoclean;

use Bread::Board;
use Moose::Util::TypeConstraints 'match_on_type';
use Plack::Middleware::HTTPExceptions;
use Try::Tiny;

use OX::Types;

extends 'Bread::Board::Container', 'Plack::Component';

has name => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->meta->name },
);

has request_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'OX::Request',
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

                for my $middleware (reverse @{ $s->param('Middleware') }) {
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

sub build_middleware {
    [ Plack::Middleware::HTTPExceptions->new(rethrow => 1) ]
}
sub middleware_dependencies { {} }

sub build_app {
    my $self = shift;
    confess(blessed($self) . " must implement the build_app method");
}
sub app_dependencies {
    return { Middleware => 'Middleware' };
}

sub _call_app {
    my $self = shift;
    my ($env) = @_;

    my $app = $self->resolve(service => 'App');
    return $app->($env);
}

sub call {
    my $self = shift;
    my ($env) = @_;

    my $res = $self->_call_app($env);

    $self->response_cb(
        $res,
        sub {
            return sub {
                my $content = shift;

                # flush all services that are request-scoped
                # after the response is returned
                $self->_flush_request_services
                    unless defined $content;

                return $content;
            };
        }
    );

    return $res;
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
