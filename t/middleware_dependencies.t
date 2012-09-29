#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Test::Requires 'MooseX::NonMoose';

{
    package Foo::Middleware;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Middleware';

    has static_root => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    sub call {
        my $self = shift;
        my ($env) = @_;
        my $res = $self->app->($env);
        unshift @{ $res->[2] }, $self->static_root;
        return $res;
    }
}

{
    package Foo;
    use OX;

    has static_root => (
        is    => 'ro',
        isa   => 'Str',
        value => 'root/static',
    );

    router as {
        wrap 'Foo::Middleware' => (
            static_root => 'static_root',
        );
        route '/foo' => sub {
            my $req = shift;
            return $req->path;
        };
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'root/static/foo', "right content");
    };

{
    package Bar;
    use OX;

    has static_root => (
        is    => 'ro',
        isa   => 'Str',
        value => '/static',
    );

    router as {
        wrap sub {
            my ($app, $s) = @_;
            my $root = $s->param('static_root');
            return sub {
                my $env = shift;
                my $res = $app->($env);
                unshift @{ $res->[2] }, $root;
                return $res;
            };
        }, (static_root => 'static_root');

        route '/foo' => sub {
            my $req = shift;
            return $req->path;
        };
    };
}

test_psgi
    app    => Bar->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/static/foo', "right content");
    };

my ($thing1, $thing2);
my ($constructor_count, $destructor_count) = (0, 0);

{
    package BazThing;
    use Moose;

    sub BUILD    { $constructor_count++ }
    sub DEMOLISH { $destructor_count++  }
}

{
    package Baz::Controller;
    use Moose;

    has thing => (
        is       => 'ro',
        isa      => 'BazThing',
        required => 1,
    );

    sub index {
        my $self = shift;
        my ($r) = @_;

        $thing1 = $self->thing;

        return 'ok';
    }
}

{
    package Baz::Middleware;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Middleware';

    has thing => (
        is       => 'ro',
        isa      => 'BazThing',
        required => 1,
    );

    sub call {
        my $self = shift;
        my ($env) = @_;

        $thing2 = $self->thing;

        return $self->app->($env);
    }
}

{
    package Baz;
    use OX;

    has thing => (
        is        => 'ro',
        isa       => 'BazThing',
        lifecycle => 'Request',
    );

    has root => (
        is           => 'ro',
        isa          => 'Baz::Controller',
        dependencies => ['thing'],
    );

    router as {
        wrap 'Baz::Middleware' => (
            thing => 'thing',
        );

        route '/' => 'root.index';
    };
}

test_psgi
    app    => Baz->new->to_app,
    client => sub {
        my $cb = shift;

        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        is($res->content, 'ok', "right content");
        isa_ok($thing1, 'BazThing');
        isa_ok($thing2, 'BazThing');
        is($thing1, $thing2);
        is($constructor_count, 1);
        is($destructor_count, 0);

        my $req1_thing = $thing1;
        undef $thing1;
        undef $thing2;

        my $req2 = HTTP::Request->new(GET => "http://localhost/");
        my $res2 = $cb->($req);
        is($res->content, 'ok', "right content");
        isa_ok($thing1, 'BazThing');
        isa_ok($thing2, 'BazThing');
        is($thing1, $thing2);
        isnt($req1_thing, $thing1);
        isnt($req1_thing, $thing2);
        is($constructor_count, 2);
        is($destructor_count, 0);

        undef $req1_thing;
        undef $thing1;
        undef $thing2;

        is($destructor_count, 2);
    };

done_testing;
