#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo::Controller;
    use Moose;
    sub foo { "foo" }
}

{
    package Foo;
    use OX;

    has foo => (
        is  => 'ro',
        isa => 'Foo::Controller',
    );

    router as {
        route '/foo' => 'foo.foo';
    };
}

{
    package Bar::Controller;
    use Moose;
    sub bar { "bar" }
}

{
    package Bar;
    use OX;

    extends 'Foo';

    has bar => (
        is  => 'ro',
        isa => 'Bar::Controller',
    );

    router as {
        route '/bar' => 'bar.bar';
        route '/baz' => 'foo.foo';
    };
}

test_psgi
    app    => Bar->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, "foo", "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar');
            my $res = $cb->($req);
            is($res->content, "bar", "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/baz');
            my $res = $cb->($req);
            is($res->content, "foo", "got the right content");
        }
    };

done_testing;
