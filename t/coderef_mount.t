#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo;
    use OX;

    router as {
        route '/' => sub { "index" };
        route '/foo' => sub {
            my $req = shift;
            return "foo: " . $req->script_name . ' ' . $req->path_info;
        };

        mount '/bar' => sub {
            my $env = shift;
            return [200, [], ["bar: $env->{SCRIPT_NAME} $env->{PATH_INFO}"]];
        };
    };
}

test_psgi
    app => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'index', "got right content for /");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'foo:  /foo', "got right content for /foo");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo/bar');
            my $res = $cb->($req);
            is($res->code, 404, "nothing routed to /foo/bar");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar');
            my $res = $cb->($req);
            is($res->content, 'bar: /bar ', "got right content for /bar");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar/baz');
            my $res = $cb->($req);
            is($res->content, 'bar: /bar /baz',
               "got right content for /bar/baz");
        }
    };

done_testing;
