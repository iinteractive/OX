package OX::Application;
use Moose;
use Bread::Board::Declare;
use namespace::autoclean;

use Bread::Board;
use Moose::Util::TypeConstraints
    qw(class_type subtype where match_on_type), as => { -as => 'mutc_as' };
use Plack::Middleware::HTTPExceptions;
use Plack::Util;
use Try::Tiny;

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
    lazy    => 1,
    builder => 'build_middleware',
    handles => {
        middleware => 'elements',
    },
);

sub BUILD {
    my $self = shift;
    container $self => as {

        container 'Router' => as {

            service 'router' => (
                block => sub {
                    my $s      = shift;
                    my $router_class = $self->router_class;
                    Class::MOP::load_class($router_class);
                    my $router = $router_class->new(
                        request_class => $self->request_class
                    );
                    $self->configure_router( $s, $router );
                    $router;
                },
                dependencies => $self->router_dependencies
            );

        };

        service App => (
            block        => sub {
                my $s = shift;

                my $router = $s->param('router');
                my $app = $self->app_from_router($router);

                my @middleware = (
                    $self->middleware,
                    Plack::Middleware::HTTPExceptions->new(rethrow => 1),
                    sub {
                        my $app = shift;
                        return sub {
                            my $env = shift;
                            $env->{'ox.router'} = $router;
                            $app->($env);
                        }
                    },
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

sub _flush_request_services {
    my $self = shift;
    my @services = $self->get_service_list;

    foreach my $service (@services) {
        my $injection = $self->get_service($service);
        if ($injection->does('Bread::Board::LifeCycle::Request')) {
            $injection->flush_instance;
        }
    }
}


sub router_class { die "No router_class specified" }
sub request_class { 'OX::Request' }
sub app_from_router {
    die "You must override app_from_router to specify how to create a PSGI"
      . " app from your router object";
}
sub router_dependencies { [] }
sub configure_router { }
sub build_middleware { [] }

# can't use 'router', since that's used as a keyword
sub get_router { shift->resolve(service => 'Router/router') }

# ... Plack::Component API

sub prepare_app {
    my $self = shift;
    $self->_app( $self->resolve(service => 'App') );
}

sub call {
    my ($self, $env) = @_;
    my $res = $self->_app->( $env );

    # flush all services that are request-scoped
    # after the response is returned
    my $flush_callback = sub {
        my $content = shift;

        $self->_flush_request_services
            unless defined $content;

        return $content;
    };

    Plack::Util::response_cb(
        $res, sub { $flush_callback }
    );

    return $res;
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

1;

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
