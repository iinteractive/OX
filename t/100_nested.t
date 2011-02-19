#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request;

{
    package Foo::Root;
    use Moose;

    has count => (
        traits  => ['Counter'],
        is      => 'ro',
        isa     => 'Int',
        default => 0,
        handles => {
            inc => 'inc',
        },
    );

    sub index {
        my $self = shift;
        my ($req) = @_;
        $self->inc;
        return [200, [], [$req->script_name . ': index ' . $self->count]];
    }

    sub foo {
        my $self = shift;
        my ($req) = @_;
        $self->inc;
        return [200, [], [$req->script_name . ': foo ' . $self->count]];
    }
}

{
    package Baz;
    use OX;

    has root => (
        is       => 'ro',
        isa      => 'Foo::Root',
        required => 1,
    );

    component 'BazRoot' => sub {
        my ($s, $app) = @_;
        $app->root;
    };

    router as {
        route '/'    => 'root.index';
        route '/foo' => 'root.foo';
    }, ('root' => depends_on('Component/BazRoot'));
}

{
    package Bar;
    use OX;

    has root => (
        is       => 'ro',
        isa      => 'Foo::Root',
        required => 1,
    );

    component 'BarRoot' => sub {
        my ($s, $app) = @_;
        $app->root;
    };

    router as {
        route '/'    => 'root.index';
        route '/foo' => 'root.foo';

        mount '/baz' => 'Baz' => (
            root => depends_on('Component/BarRoot'),
        );
    }, ('root' => depends_on('Component/BarRoot'));
}

{
    package Foo;
    use OX;

    component 'FooRoot' => 'Foo::Root' => {
        lifecycle => 'Singleton',
    };

    router as {
        route '/'    => 'root.index';
        route '/foo' => 'root.foo';

        mount '/bar' => 'Bar' => (
            root => depends_on('Component/FooRoot'),
        );
    }, ('root' => depends_on('Component/FooRoot'));
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => "http://localhost");
            my $res = $cb->($req);
            is($res->content, ': index 1', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/");
            my $res = $cb->($req);
            is($res->content, ': index 2', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/foo");
            my $res = $cb->($req);
            is($res->content, ': foo 3', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar");
            my $res = $cb->($req);
            is($res->content, '/bar: index 4', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/");
            my $res = $cb->($req);
            is($res->content, '/bar: index 5', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/foo");
            my $res = $cb->($req);
            is($res->content, '/bar: foo 6', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/baz");
            my $res = $cb->($req);
            is($res->content, '/bar/baz: index 7', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/baz/");
            my $res = $cb->($req);
            is($res->content, '/bar/baz: index 8', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/baz/foo");
            my $res = $cb->($req);
            is($res->content, '/bar/baz: foo 9', "right content");
        }
    };

done_testing;
