#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Path::Router;
use Plack::Test;

use Path::Router;
use Plack::App::Path::Router::PSGI;

{
    package Foo;
    use OX;

    sub app_from_router {
        my $self = shift;
        my ($router) = @_;

        return Plack::App::Path::Router::PSGI->new(
            router => $router,
        )->to_app;
    }

    my $router = Path::Router->new;
    $router->add_route('/' => (
        target => sub { [200, [], ['root']] }
    ));
    $router->add_route('/:number' => (
        validations => {
            number => 'Int',
        },
        target => sub {
            my $env = shift;
            my ($num) = @{ $env->{'plack.router.match.args'} };
            return [200, [], ["got $num"]];
        }
    ));

    router $router;
}

{
    package Bar::Router;
    use Moose;
    extends 'Path::Router';

    sub BUILD {
        my $self = shift;

        $self->add_route('/' => (
            target => sub { [200, [], ['root']] }
        ));
        $self->add_route('/:number' => (
            validations => {
                number => 'Int',
            },
            target => sub {
                my $env = shift;
                my ($num) = @{ $env->{'plack.router.match.args'} };
                return [200, [], ["got $num"]];
            }
        ));
    }
}

{
    package Bar;
    use OX;

    sub app_from_router {
        my $self = shift;
        my ($router) = @_;

        return Plack::App::Path::Router::PSGI->new(
            router => $router,
        )->to_app;
    }

    router 'Bar::Router';
}

{
    package Baz::Router;
    use Moose;
    extends 'Path::Router';

    sub BUILD {
        my $self = shift;

        $self->add_route('/' => (
            target => sub { shift->new_response([ 200, [], ['root'] ]) }
        ));
        $self->add_route('/:number' => (
            validations => {
                number => 'Int',
            },
            target => sub {
                my $req = shift;
                my ($num) = @_;
                return "got $num";
            }
        ));
    }
}

{
    package Baz;
    use OX;

    router 'Baz::Router';
}

for my $class (qw(Foo Bar Baz)) {
    my $app = $class->new;
    my $router = $app->router;

    isa_ok($app, $class);

    path_ok($router, $_, '... ' . $_ . ' is a valid path')
        for qw[
            /
            /10
            /246
        ];

    routes_ok($router, {
        ''    => {},
        '10'  => { number => 10  },
        '246' => { number => 246 },
    },
    "... our routes are valid");

    test_psgi
        app => $app->to_app,
        client => sub {
            my $cb = shift;
            {
                my $req = HTTP::Request->new(GET => "http://localhost/");
                my $res = $cb->($req);
                is($res->content, 'root', "right content for /");
            }
            {
                my $req = HTTP::Request->new(GET => "http://localhost/10");
                my $res = $cb->($req);
                is($res->content, 'got 10', "right content for /10");
            }
            {
                my $req = HTTP::Request->new(GET => "http://localhost/246");
                my $res = $cb->($req);
                is($res->content, 'got 246', "right content for /246");
            }
        };
}

done_testing;
