#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request;

{
    package Foo;
    use Moose;

    extends 'OX::Application';

    sub configure_router {
        my ($self, $s, $router) = @_;

        $router->add_route('/foo',
            target => sub {
                my $req = shift;
                return [200, [], [$req->path]];
            }
        );
    }
}

{
    package Foo::Middleware;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Middleware';

    has uc => (
        is      => 'ro',
        isa     => 'Bool',
        default => 1,
    );

    has append => (
        is      => 'ro',
        isa     => 'Str',
        default => '',
    );

    sub call {
        my $self = shift;
        my ($env) = @_;

        my $res = $self->app->($env);
        $res->[2]->[0] .= $self->append;
        $res->[2]->[0] = uc $res->[2]->[0] if $self->uc;
        return $res;
    }
}

my $mw1 = sub {
    my $app = shift;
    return sub {
        my $env = shift;
        my $res = $app->($env);
        $res->[2]->[0] = scalar reverse $res->[2]->[0];
        return $res;
    };
};
my $mw2 = 'Foo::Middleware';
my $mw3 = Foo::Middleware->new(uc => 0, append => 'bar');

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/foo', "right content");
    };

test_psgi
    app    => Foo->new(middleware => [$mw1])->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'oof/', "right content");
    };

test_psgi
    app    => Foo->new(middleware => [$mw2])->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/FOO', "right content");
    };

test_psgi
    app    => Foo->new(middleware => [$mw3])->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, '/foobar', "right content");
    };

test_psgi
    app    => Foo->new(middleware => [$mw1, $mw2, $mw3])->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'OOF/bar', "right content");
    };

test_psgi
    app    => Foo->new(middleware => [$mw3, $mw2, $mw1])->to_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/foo");
        my $res = $cb->($req);
        is($res->content, 'RABOOF/', "right content");
    };

done_testing;
