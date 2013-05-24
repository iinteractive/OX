#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request;

my %calls;

{
    package Foo::Middleware;
    use Moose;

    extends 'Plack::Middleware';

    sub prepare_app {
        my ( $self ) = @_;
        $calls{ 'prepare_app' }++;
    }

    sub call {
        my $self = shift;
        my ($env) = @_;

        $calls{ 'call' }++;

        return $self->app->($env);
    }
}

{
    package Foo;
    use OX;

    router as {
        wrap 'Foo::Middleware';
        route '/' => sub { "root" } => (
            name => 'root',
        );
    }
}

my $app = Foo->new->to_app;

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res1 = $cb->($req);
            my $res2 = $cb->($req);
        }
    };
test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res1 = $cb->($req);
            my $res2 = $cb->($req);
        }
    };

is($calls{call},4,'call was called 4 times');
is($calls{prepare_app},1,'prepare_app was called once');

done_testing;
