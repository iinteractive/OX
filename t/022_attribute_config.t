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
        traits  => ['OX::Config'],
        is      => 'ro',
        isa     => 'Str',
        default => 'BAR',
    );

    component Model => 'Foo::Model', (
        bar => depends_on('/Config/bar'),
    );
    component Root => 'Foo::Root', (
        model => depends_on('/Component/Model'),
    );

    router as {
        route '/' => 'root.index';
    }, (root => depends_on('/Component/Root'));
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
