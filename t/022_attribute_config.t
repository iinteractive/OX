#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo::Model;
    use Moose;

    has bar => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );
}

{
    package Foo::Root;
    use Moose;

    has model => (
        is       => 'ro',
        isa      => 'Foo::Model',
        required => 1,
    );

    sub index {
        my $self = shift;
        return $self->model->bar;
    }
}

{
    package Foo;
    use OX;

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        value => 'BAR',
    );

    has model => (
        is           => 'ro',
        isa          => 'Foo::Model',
        dependencies => ['bar'],
    );

    has root => (
        is    => 'ro',
        isa   => 'Foo::Root',
        infer => 1,
    );

    router as {
        route '/' => 'root.index';
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'BAR', "got right content");
        }
    };

test_psgi
    app    => Foo->new(bar => 'baz')->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'baz', "got right content");
        }
    };

done_testing;
