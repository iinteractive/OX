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
        is  => 'ro',
        isa => 'Foo::Root',
    );

    has middleware => (
        is  => 'ro',
        isa => 'ArrayRef',
    );

    sub build_middleware { shift->middleware }

    router as {
        route '/'    => 'root.index';
        route '/foo' => 'root.foo';
    };
}

{
    package Baz::Middleware;
    use Moose;

    extends 'Plack::Middleware';

    sub call {
        my $self = shift;
        my ($env) = @_;

        my $res = $self->app->($env);
        $res->[2]->[0] = uc $res->[2]->[0];
        return $res;
    }
}

{
    package Bar;
    use OX;

    has root => (
        is  => 'ro',
        isa => 'Foo::Root',
    );

    has baz_middleware => (
        is    => 'ro',
        isa   => 'ArrayRef',
        block => sub {
            [
                'Baz::Middleware',
                sub {
                    my $app = shift;
                    return sub {
                        my $env = shift;
                        my $res = $app->($env);
                        $res->[2]->[0] = scalar reverse $res->[2]->[0];
                        return $res;
                    };
                },
            ]
        },
    );

    router as {
        route '/'    => 'root.index';
        route '/foo' => 'root.foo';

        mount '/baz' => 'Baz' => (
            root       => 'root',
            middleware => 'baz_middleware',
        );
    };
}

{
    package Foo;
    use OX;

    has root => (
        is        => 'ro',
        isa       => 'Foo::Root',
        lifecycle => 'Singleton',
    );

    router as {
        route '/'    => 'root.index';
        route '/foo' => 'root.foo';

        mount '/bar' => 'Bar' => (
            root => 'root',
        );
    };

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
            is($res->content, '7 XEDNI :ZAB/RAB/', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/baz/");
            my $res = $cb->($req);
            is($res->content, '8 XEDNI :ZAB/RAB/', "right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/baz/foo");
            my $res = $cb->($req);
            is($res->content, '9 OOF :ZAB/RAB/', "right content");
        }
    };

done_testing;
