#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

{
    package MyApp::Controller::Foo;
    use Moose;

    sub index {
        my $self = shift;
        my ($r, $name) = @_;

        return "foo index";
    }
}

{
    package MyApp::Controller::Bar;
    use Moose;

    sub get {
        my $self = shift;
        my ($r, $name) = @_;

        return "bar get";
    }
}

{
    package MyApp;
    use OX;

    has foo => (
        is  => 'ro',
        isa => 'MyApp::Controller::Foo',
    );

    has bar => (
        is  => 'ro',
        isa => 'MyApp::Controller::Bar',
    );

    router as {
        route '/lookup/:id' => sub { $_[0]->uri_for($_[1]) };

        route '/route1' => 'foo.index';
        route '/route2' => 'bar';
    };
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/lookup/foo.index');
            ok($res->is_success);
            is($res->content, "/route1");
        }
        {
            my $res = $cb->(GET '/lookup/bar');
            ok($res->is_success);
            is($res->content, "/route2");
        }
    };

{
    package MyApp2;
    use OX;

    has foo => (
        is  => 'ro',
        isa => 'MyApp::Controller::Foo',
    );

    has bar => (
        is  => 'ro',
        isa => 'MyApp::Controller::Bar',
    );

    router as {
        route '/lookup/:id' => sub { $_[0]->uri_for($_[1]) };

        route '/route1' => 'foo.index', (
            name => 'manual_foo',
        );
        route '/route2' => 'bar', (
            name => 'manual_bar',
        );
    };
}

test_psgi
    app    => MyApp2->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/lookup/foo.index');
            ok(!$res->is_success);
        }
        {
            my $res = $cb->(GET '/lookup/bar');
            ok(!$res->is_success);
        }
        {
            my $res = $cb->(GET '/lookup/manual_foo');
            ok($res->is_success);
            is($res->content, "/route1");
        }
        {
            my $res = $cb->(GET '/lookup/manual_bar');
            ok($res->is_success);
            is($res->content, "/route2");
        }
    };

done_testing;
