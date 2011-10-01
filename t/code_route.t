#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo;
    use OX;

    router as {
        route '/' => sub { 'index' };
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
        {
            my $req = HTTP::Request->new(GET => "http://localhost/");
            my $res = $cb->($req);
            is($res->content, 'index', "right content for /");
        }
        {
            my $req = HTTP::Request->new(GET => "http://localhost/foo");
            my $res = $cb->($req);
            is($res->content, '/foo', "right content for /foo");
        }
    };

done_testing;
