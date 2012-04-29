#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Test::Requires { 'HTTP::Throwable' => 0.010 };
use Try::Tiny;

{
    package Foo::Controller;
    use Moose;
    use HTTP::Throwable::Factory qw(http_throw);

    sub foo {
        http_throw(Found => { location => '/bar' });
    }

    sub bar {
        die "we had an error";
    }
}

{
    package Foo;
    use OX;

    has controller => (
        is  => 'ro',
        isa => 'Foo::Controller',
    );

    router as {
        route '/:action' => 'controller._';
    };
}

my $app = sub {
    my $env = shift;
    return try {
        Foo->new->to_app->($env);
    }
    catch {
        [500, ['X-Exception-Thrown' => 1], ["$_"]];
    };
};

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->code, 302, "right code");
            is($res->header('Location'), '/bar', "right location");
            ok(!defined($res->header('X-Exception-Thrown')),
               "exception wasn't rethrown");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar');
            my $res = $cb->($req);
            is($res->code, 500, "right code");
            like($res->content, qr/we had an error/, "right content");
            is($res->header('X-Exception-Thrown'), 1, "exception was rethrown");
        }
    };

done_testing;
