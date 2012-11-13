#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

sub filter (&) {
    my $code = shift;
    return sub {
        my $app = shift;
        return sub {
            my $env = shift;
            my $res = $app->($env);
            $res->[2][0] = $code->($res->[2][0]);
            return $res;
        };
    };
}

{
    package MyApp;
    use OX;

    router as {
        wrap ::filter { "$_[0] MyApp(1)" };
        wrap ::filter { "$_[0] MyApp(2)" };

        route '/'    => sub { "base" };
        route '/foo' => sub { "base foo" };
    };
}

{
    package MyApp2;
    use OX;

    extends 'MyApp';

    router as {
        wrap ::filter { "$_[0] MyApp2(1)" };
        wrap ::filter { "$_[0] MyApp2(2)" };

        route '/'    => sub { "subclass" };
        route '/bar' => sub { "subclass bar" };
    }
}

test_psgi
    app => MyApp2->new->to_app,
    client => sub {
        my $cb = shift;

        my $middleware_id = 'MyApp(2) MyApp(1) MyApp2(2) MyApp2(1)';
        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "subclass $middleware_id");
        }

        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "base foo $middleware_id");
        }

        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, "subclass bar $middleware_id");
        }
    };

{
    package MyApp3;
    use OX;

    extends 'MyApp2';

    router as {
        wrap ::filter { "$_[0] MyApp3(1)" };
        wrap ::filter { "$_[0] MyApp3(2)" };

        route '/'    => sub { "subsubclass" };
        route '/baz' => sub { "subsubclass baz" };
    }
}

test_psgi
    app => MyApp3->new->to_app,
    client => sub {
        my $cb = shift;

        my $middleware_id = 'MyApp(2) MyApp(1) MyApp2(2) MyApp2(1) MyApp3(2) MyApp3(1)';
        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "subsubclass $middleware_id");
        }

        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "base foo $middleware_id");
        }

        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, "subclass bar $middleware_id");
        }

        {
            my $res = $cb->(GET '/baz');
            ok($res->is_success);
            is($res->content, "subsubclass baz $middleware_id");
        }
    };

done_testing;
