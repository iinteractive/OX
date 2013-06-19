#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

my $called;
my $prepare_app;

{
    package MyApp::Foo;
    use Moose;

    has foo => (
        is      => 'ro',
        isa     => 'Str',
        default => 'FOO',
    );
}

{
    package MyApp::Middleware;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Middleware';

    has foo => (
        is       => 'ro',
        isa      => 'MyApp::Foo',
        required => 1,
    );

    sub BUILD {
        $called++;
    }

    sub prepare_app {
        $prepare_app++;
    }

    sub call {
        my $self = shift;
        my ($env) = @_;

        my $res = $self->app->($env);
        push @{ $res->[1] }, ('X-Foo' => $self->foo->foo);
        return $res;
    }
}

{
    package MyApp;
    use OX;

    has foo => (
        is  => 'ro',
        isa => 'MyApp::Foo',
    );

    router as {
        wrap 'MyApp::Middleware', (foo => 'foo');

        route '/' => sub {
            my $req = shift;
            return $req->path;
        };
    };
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        $called = 0;
        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, '/');
            is($res->header('X-Foo'), 'FOO');
            is($called, 1);
            is($prepare_app, 1);
        }

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, '/');
            is($res->header('X-Foo'), 'FOO');
            is($called, 2);
            is($prepare_app, 2);
        }
    };

{
    package MyApp2;
    use OX;

    has foo => (
        is  => 'ro',
        isa => 'MyApp::Foo',
    );

    router as {
        wrap 'Singleton', 'MyApp::Middleware', (foo => 'foo');

        route '/' => sub {
            my $req = shift;
            return $req->path;
        };
    };
}

test_psgi
    app    => MyApp2->new->to_app,
    client => sub {
        my $cb = shift;

        $called = 0;
        $prepare_app = 0;
        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, '/');
            is($res->header('X-Foo'), 'FOO');
            is($called, 1);
            is($prepare_app, 1);
        }

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, '/');
            is($res->header('X-Foo'), 'FOO');
            is($called, 1);
            is($prepare_app, 1);
        }
    };

done_testing;
