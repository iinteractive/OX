#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package FooController;
    use Moose;

    sub foo { "foo" }
    sub bar { "bar" }
    sub baz { "baz" }
}

{
    package Foo;
    use OX;

    has foo => (
        is  => 'ro',
        isa => 'FooController',
    );

    router as {
        route '/:action' => 'foo._' => (
            action => { isa => 'Str' },
        );
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'foo', "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar');
            my $res = $cb->($req);
            is($res->content, 'bar', "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/baz');
            my $res = $cb->($req);
            is($res->content, 'baz', "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/quux');
            my $res = $cb->($req);
            is($res->code, 500, "got the right code");
        }
    };

{
    package Bar;
    use OX;
    use Moose::Util::TypeConstraints qw(enum);

    has foo => (
        is  => 'ro',
        isa => 'FooController',
    );

    router as {
        route '/:action' => 'foo._' => (
            action => { isa => enum(['foo', 'bar', 'baz']) },
        );
    };
}

test_psgi
    app    => Bar->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'foo', "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar');
            my $res = $cb->($req);
            is($res->content, 'bar', "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/baz');
            my $res = $cb->($req);
            is($res->content, 'baz', "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/quux');
            my $res = $cb->($req);
            is($res->code, 404, "got the right code");
        }
    };

done_testing;
