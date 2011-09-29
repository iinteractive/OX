#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

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

done_testing;
