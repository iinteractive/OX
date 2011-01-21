#!/usr/bin/env perl
use strict;
use warnings;
use Test::More skip_all => "doesn't work yet";
use Test::Path::Router;
use Plack::Test;

# this would be nice to support sometime, but i'm really not sure what the
# semantics should look like exactly

{
    package Nested::Controller;
    use Moose;
    sub print {
        my $self = shift;
        my ($r) = @_;
        return $r->path;
    }
}

{
    package Nested::Controller2;
    use Moose;
    sub print {
        my $self = shift;
        my ($r) = @_;
        return scalar reverse $r->path;
    }
}

{
    package Nested;
    use OX;

    component Controller  => 'Nested::Controller';
    component Controller2 => 'Nested::Controller2';

    router as {

        route '/foo' => 'root.print';

        route '/bar' => router as {
            route '/foo' => 'root.print',
        };

        route '/baz' => router as {
            route '/foo' => 'root.print',
        }, (root => depends_on('/Component/Controller2'));

    }, (root => depends_on('/Component/Controller'));
}

my $app = Nested->new;
my $router = $app->resolve(service => 'Router');

path_ok($router, $_, '... ' . $_ . ' is a valid path')
    for qw[
        /foo
        /bar/foo
        /baz/foo
    ];

routes_ok($router, {
    'foo'     => { controller => 'root', action => 'print' },
    'bar/foo' => { controller => 'root', action => 'print' },
    'baz/foo' => { controller => 'root', action => 'print' }, # ???
},
"... our routes are valid");

test_psgi
    app => $app->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => "http://localhost/foo");
            my $res = $cb->($req);
            is($res->content, '/foo', "right content for /foo");
        }
        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/foo");
            my $res = $cb->($req);
            is($res->content, '/bar/foo', "right content for /bar/foo");
        }
        {
            my $req = HTTP::Request->new(GET => "http://localhost/baz/foo");
            my $res = $cb->($req);
            is($res->content, 'oof/zab/', "right content for /baz/foo");
        }
    };

done_testing;
