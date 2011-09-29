#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

my $built = 0;
my $demolished = 0;
{
    package Controller;
    use Moose;

    sub BUILD { $built++ }

    sub DEMOLISH { $demolished++ }

    sub index { $built }
}

{
    package Foo;
    use OX;

    has root => (is => 'ro', isa => 'Controller');

    router as {
        route '/' => 'root.index';
    };
}

is($built, 0);
is($demolished, 0);
my $app = Foo->new;
is($built, 0);
is($demolished, 0);
my $psgi = $app->to_app;
is($built, 0);
is($demolished, 0);

test_psgi
    app => $psgi,
    client => sub {
        my $cb = shift;
        is($built, 0);
        is($demolished, 0);
        for (1 .. 3) {
            my $req = HTTP::Request->new(GET => "http://localhost");
            my $res = $cb->($req);
            is($built, $_);
            is($demolished, $_);
        }
    };

done_testing;
