#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo::Controller;
    use Moose;
    sub foo { "foo" }
    sub with_args {
        my $self = shift;
        my ($r, $thing) = @_;
        return "$thing: " . join(' ', sort keys %{ $r->mapping });
    }
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
        route '/with_args/:thing' => 'foo.with_args';
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
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/with_args/8');
            my $res = $cb->($req);
            is($res->content, "8: action controller thing", "got the right content");
        }
    };

{
    package Baz::Controller;
    use Moose;
    sub baz { "baz" }
}

{
    package Baz;
    use OX;

    extends 'Bar';

    has baz => (
        is  => 'ro',
        isa => 'Baz::Controller',
    );

    router as {
        route '/baz' => 'baz.baz';
        route '/with_args/:other' => 'foo.with_args';
    };
}

test_psgi
    app    => Baz->new->to_app,
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
            is($res->content, "baz", "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/with_args/7');
            my $res = $cb->($req);
            is($res->content, "7: action controller other", "got the right content");
        }
    };

done_testing;
