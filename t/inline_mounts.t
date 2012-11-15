#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

{
    package MyApp;
    use OX;

    router as {
        route '/' => sub { "root" };
        mount '/foo' => router as {
            route '/' => sub { "foo root" };
            route '/bar' => sub { "foo bar" };
        };
    };
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "root");
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "foo root");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "foo bar");
        }
        {
            my $res = $cb->(GET '/foo/baz');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/bar');
            ok(!$res->is_success);
            is($res->code, 404);
        }
    };

done_testing;
