#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Bar::Middleware;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Middleware';

    sub call {
        my $self = shift;
        my ($env) = @_;
        my $res = $self->app->($env);
        $res->[2]->[0] = uc($res->[2]->[0]);
        return $res;
    }
}

{
    package Bar;
    use OX;

    router as {
        route '/baz' => sub { "/bar/baz" };
    };
}

{
    package Foo::Root;
    use Moose;

    has [qw(foo bar)] => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    sub index {
        my $self = shift;
        return "Foo::Root::index: " . $self->foo . ' ' . $self->bar;
    }
}

{
    package Foo;
    use OX;

    config foo => sub {
        my $s = shift;
        return $s->param('param');
    }, (param => config(foo_param => 'foo_param'));

    component bar => sub {
        my $s = shift;
        return $s->param('param');
    }, (param => config(bar_param => 'bar_param'));

    router as {
        route '/foo' => 'root.index';

        mount '/bar' => 'Bar' => (
            middleware => config('bar_middleware' => sub { ['Bar::Middleware'] }),
        );
    }, (root => component('Root' => 'Foo::Root' => (
                              # XXX: it'd be nice if these worked without the
                              # leading / too, but that's complicated
                              foo => depends_on('/Config/foo'),
                              bar => depends_on('/Component/bar'),
                          )),
    );

}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'Foo::Root::index: foo_param bar_param',
               "right content for /foo");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar/baz');
            my $res = $cb->($req);
            is($res->content, '/BAR/BAZ', "right content for /bar/baz");
        }
    };

done_testing;
