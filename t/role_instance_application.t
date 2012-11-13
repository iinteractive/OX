#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

{
    package MyApp::Controller::Root;
    use Moose;

    sub foo { "foo" }
    sub bar { "bar" }
    sub baz { "baz" }
}

{
    package MyApp::Role;
    use OX::Role;

    router as {
        mount '/mount' => sub { [ 200, [], ["mounted app: $_[0]->{PATH_INFO}"] ] };
        route '/foo' => 'root.baz';
        route '/bar' => 'root.baz';
        route '/baz' => 'root.baz';
    }
}

{
    package MyApp::Super;
    use OX;

    has root => (
        is  => 'ro',
        isa => 'MyApp::Controller::Root',
    );

    router as {
        route '/foo' => 'root.foo';
    }
}

{
    package MyApp;
    use OX;

    extends 'MyApp::Super';

    router as {
        route '/bar' => 'root.bar';
    }
}

{
    my $app = MyApp->new;
    test_psgi
        app => $app->to_app,
        client => sub {
            my $cb = shift;

            {
                my $res = $cb->(GET '/foo');
                ok($res->is_success);
                is($res->content, 'foo');
            }
            {
                my $res = $cb->(GET '/bar');
                ok($res->is_success);
                is($res->content, 'bar');
            }
            {
                my $res = $cb->(GET '/baz');
                ok(!$res->is_success);
                is($res->code, 404);
            }
            {
                my $res = $cb->(GET '/mount');
                ok(!$res->is_success);
                is($res->code, 404);
            }
        };

    Moose::Util::apply_all_roles($app, 'MyApp::Role');
    test_psgi
        app => $app->to_app,
        client => sub {
            my $cb = shift;

            {
                my $res = $cb->(GET '/foo');
                ok($res->is_success);
                is($res->content, 'baz');
            }
            {
                my $res = $cb->(GET '/bar');
                ok($res->is_success);
                is($res->content, 'baz');
            }
            {
                my $res = $cb->(GET '/baz');
                ok($res->is_success);
                is($res->content, 'baz');
            }
            {
                my $res = $cb->(GET '/mount/foo');
                ok($res->is_success);
                is($res->content, 'mounted app: /foo');
            }
        };
}

done_testing;
