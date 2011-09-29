#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request;

my $n = 0;
{
    package Thing;
    use Moose;

    sub BUILD { ++$n }
}

{
    package Foo::Root;
    use Moose;

    has thing => (
        is       => 'ro',
        isa      => 'Thing',
        required => 1,
    );

    has thing2 => (
        is       => 'ro',
        isa      => 'Thing',
        required => 1,
    );

    sub index {
        my $self = shift;
        $self->thing == $self->thing2 ? "$n 1" : "$n 0";
    }
}

{
    package Foo;
    use OX;

    has thing => (
        is        => 'ro',
        isa       => 'Thing',
        lifecycle => 'Request',
    );
    has root => (
        is    => 'ro',
        isa   => 'Foo::Root',
        infer => 1,
    );

    router as {
        route '/' => 'root.index'
    };
}

test_psgi
    app => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        for (1 .. 2) {
            my $req = HTTP::Request->new(GET => "http://localhost");
            my $res = $cb->($req);
            is($res->content, "$_ 1");
        }
    };

done_testing;
