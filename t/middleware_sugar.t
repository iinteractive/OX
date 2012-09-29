#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Test::Requires 'MooseX::NonMoose';

{
    package Foo;
    use OX;

    router as {
        wrap sub {
            my $app = shift;
            return sub {
                my $env = shift;
                $env->{'test.foo'} = 'FOO';
                $app->($env);
            };
        };

        route '/' => sub {
            my $req = shift;
            $req->env->{'test.foo'};
        };
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'FOO', "got the right content");
        }
    };

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
    package Bar1;
    use OX;

    router as {
        route '/foo' => sub {
            my $req = shift;
            return [200, [], [$req->path]];
        };
    };
}

{
    package Bar2;
    use OX;

    router as {
        wrap $mw1;

        route '/foo' => sub {
            my $req = shift;
            return [200, [], [$req->path]];
        };
    };
}

{
    package Bar3;
    use OX;

    router as {
        wrap $mw2;

        route '/foo' => sub {
            my $req = shift;
            return [200, [], [$req->path]];
        };
    };
}

{
    package Bar4;
    use OX;

    router as {
        wrap $mw3;

        route '/foo' => sub {
            my $req = shift;
            return [200, [], [$req->path]];
        };
    };
}

{
    package Bar5;
    use OX;

    router as {
        wrap $mw1;
        wrap $mw2;
        wrap $mw3;

        route '/foo' => sub {
            my $req = shift;
            return [200, [], [$req->path]];
        };
    };
}

{
    package Bar6;
    use OX;

    router as {
        wrap $mw3;
        wrap $mw2;
        wrap $mw1;

        route '/foo' => sub {
            my $req = shift;
            return [200, [], [$req->path]];
        };
    };
}

test_psgi
    app    => Bar1->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/foo', "right content");
    };

test_psgi
    app    => Bar2->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'oof/', "right content");
    };

test_psgi
    app    => Bar3->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/FOO', "right content");
    };

test_psgi
    app    => Bar4->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/foobar', "right content");
    };

test_psgi
    app    => Bar5->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'RABOOF/', "right content");
    };

test_psgi
    app    => Bar6->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'OOF/bar', "right content");
    };

done_testing;
