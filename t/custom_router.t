#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use OX::Request;

{
    package Foo::Model;
    use Moose;

    has val => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );
}

{
    package Foo::Router;
    use Moose;

    has model => (
        is       => 'ro',
        isa      => 'Foo::Model',
        required => 1,
    );
}

{
    package Foo;
    use OX;

    has val => (
        is    => 'ro',
        isa   => 'Str',
        value => 'VAL',
    );

    has model => (
        is  => 'ro',
        isa => 'Foo::Model',
        dependencies => ['val'],
    );

    router 'Foo::Router' => (
        model => 'model',
    );

    sub app_from_router {
        my $self = shift;
        my ($router) = @_;
        return sub {
            my $req = OX::Request->new_from_env(shift);
            # peeking at the internals here just to ensure the proper thing
            # is being used
            [200, [], [$req->_router->model->val . ': ' . $req->path]];
        };
    }
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'VAL: /', "right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'VAL: /foo', "right content");
        }
    };

test_psgi
    app    => Foo->new(val => 'val')->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'val: /', "right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'val: /foo', "right content");
        }
    };

done_testing;
