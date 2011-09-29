#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Baz;
    use OX;

    router as {
        route '/' => sub {
            my $req = shift;
            my $foo = $req->uri_for({foo => 'bar'});
            my $bar = $req->uri_for({controller => 'bar', action => 'index'});
            return "$foo:$bar";
        };
        route '/foo' => sub { 'foo' }, (
            'foo' => 'bar',
        );
        route '/bar' => 'bar.index';
    };
}

{
    package Foo;
    use OX;

    router as {
        route '/' => sub {
            my $req = shift;
            my $foo = $req->uri_for({foo => 'bar'});
            my $bar = $req->uri_for({controller => 'bar', action => 'index'});
            return "$foo:$bar";
        };
        route '/foo' => sub { 'foo' }, (
            'foo' => 'bar',
        );
        route '/bar' => 'bar.index';

        mount '/baz' => 'Baz';
    };
}

test_psgi
    app => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, '/foo:/bar', "got the right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/baz/');
            my $res = $cb->($req);
            is($res->content, '/baz/foo:/baz/bar', "got the right content");
        }
    };

done_testing;
