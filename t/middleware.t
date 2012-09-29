#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Test::Requires 'MooseX::NonMoose';

use HTTP::Request;

{
    package Foo::Middleware;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Middleware';

    has uc => (
        is      => 'ro',
        isa     => 'Bool',
        default => 1,
    );

    has append => (
        is      => 'ro',
        isa     => 'Str',
        default => '',
    );

    sub call {
        my $self = shift;
        my ($env) = @_;

        my $res = $self->app->($env);
        $res->[2]->[0] .= $self->append;
        $res->[2]->[0] = uc $res->[2]->[0] if $self->uc;
        return $res;
    }
}

my $mw1 = sub {
    my $app = shift;
    return sub {
        my $env = shift;
        my $res = $app->($env);
        $res->[2]->[0] = scalar reverse $res->[2]->[0];
        return $res;
    };
};
my $mw2 = 'Foo::Middleware';
my $mw3 = Foo::Middleware->new(uc => 0, append => 'bar');

{
    package Foo1;
    use Moose;

    extends 'OX::Application';
    with 'OX::Application::Role::Router::Path::Router';

    sub build_middleware { [] }

    sub configure_router {
        my ($self, $router) = @_;

        $router->add_route('/foo',
            target => sub {
                my $req = shift;
                return [200, [], [$req->path]];
            }
        );
    }
}

{
    package Foo2;
    use Moose;

    extends 'OX::Application';
    with 'OX::Application::Role::Router::Path::Router';

    sub build_middleware { [$mw1] }

    sub configure_router {
        my ($self, $router) = @_;

        $router->add_route('/foo',
            target => sub {
                my $req = shift;
                return [200, [], [$req->path]];
            }
        );
    }
}

{
    package Foo3;
    use Moose;

    extends 'OX::Application';
    with 'OX::Application::Role::Router::Path::Router';

    sub build_middleware { [$mw2] }

    sub configure_router {
        my ($self, $router) = @_;

        $router->add_route('/foo',
            target => sub {
                my $req = shift;
                return [200, [], [$req->path]];
            }
        );
    }
}

{
    package Foo4;
    use Moose;

    extends 'OX::Application';
    with 'OX::Application::Role::Router::Path::Router';

    sub build_middleware { [$mw3] }

    sub configure_router {
        my ($self, $router) = @_;

        $router->add_route('/foo',
            target => sub {
                my $req = shift;
                return [200, [], [$req->path]];
            }
        );
    }
}

{
    package Foo5;
    use Moose;

    extends 'OX::Application';
    with 'OX::Application::Role::Router::Path::Router';

    sub build_middleware { [$mw1, $mw2, $mw3] }

    sub configure_router {
        my ($self, $router) = @_;

        $router->add_route('/foo',
            target => sub {
                my $req = shift;
                return [200, [], [$req->path]];
            }
        );
    }
}

{
    package Foo6;
    use Moose;

    extends 'OX::Application';
    with 'OX::Application::Role::Router::Path::Router';

    sub build_middleware { [$mw3, $mw2, $mw1] }

    sub configure_router {
        my ($self, $router) = @_;

        $router->add_route('/foo',
            target => sub {
                my $req = shift;
                return [200, [], [$req->path]];
            }
        );
    }
}

test_psgi
    app    => Foo1->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/foo', "right content");
    };

test_psgi
    app    => Foo2->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'oof/', "right content");
    };

test_psgi
    app    => Foo3->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/FOO', "right content");
    };

test_psgi
    app    => Foo4->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/foobar', "right content");
    };

test_psgi
    app    => Foo5->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'RABOOF/', "right content");
    };

test_psgi
    app    => Foo6->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'OOF/bar', "right content");
    };

done_testing;
