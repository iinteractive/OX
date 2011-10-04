#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo::Controller;
    use Moose;

    sub index    { "index for foo" }
    sub foo      { "/foo/foo" }
    sub bar      { "/foo/bar" }
    sub specific { "/foo/specific" }

    sub get      { "GET on foo" }
}

{
    package Bar::Controller;
    use Moose;

    sub index          { "index for bar" }
    sub thing          { "/bar/thing" }
    sub other_thing    { "/bar/other_thing" }
    sub specific_thing { "specific thing for bar" }

    sub any            { "any method on bar" }
}

{
    package Baz::Controller;
    use Moose;

    sub index { "index for baz" }
    sub foo   { "/baz/foo" }

    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        (my $meth = $AUTOLOAD) =~ s/.*:://;
        "got autoloaded method $meth for baz";
    }
    sub can { 1 }
}

{
    package Specific::Action;
    use Moose;

    sub get  { "specific GET" }
    sub post { "specific POST" }
    sub any  { "specific any method" }
}

{
    package Foo;
    use OX;
    use Moose::Util::TypeConstraints qw(enum);

    has foo => (
        is  => 'ro',
        isa => 'Foo::Controller',
    );

    has bar => (
        is  => 'ro',
        isa => 'Bar::Controller',
    );

    has baz => (
        is  => 'ro',
        isa => 'Baz::Controller',
    );

    has specific_action => (
        is  => 'ro',
        isa => 'Specific::Action',
    );

    router as {

        route '/foo/:action'  => 'foo._';
        route '/foo/specific' => sub { "got a specific path under /foo" };

        route '/bar/:thing' => sub {
            my ($req, $thing) = @_;
            return "got $thing for bar";
        }, (thing => { isa => enum(['thing', 'other_thing']) });
        route '/bar/thing'  => 'bar.specific_thing';

        route '/baz' => 'baz.index';

        route '/controller/:controller'         => '_.index';
        route '/controller/:controller/:action' => '_._';

        route '/action/:action' => '_';
        route '/action/specific' => 'specific_action';
    };
}

my %expected = (
    '/foo/foo'                    => '/foo/foo',
    '/foo/bar'                    => '/foo/bar',
    '/foo/specific'               => 'got a specific path under /foo',
    '/bar/thing'                  => 'specific thing for bar',
    '/bar/other_thing'            => 'got other_thing for bar',
    '/baz'                        => 'index for baz',
    '/controller/foo'             => 'index for foo',
    '/controller/bar'             => 'index for bar',
    '/controller/baz'             => 'index for baz',
    '/controller/foo/foo'         => '/foo/foo',
    '/controller/foo/specific'    => '/foo/specific',
    '/controller/bar/thing'       => '/bar/thing',
    '/controller/bar/other_thing' => '/bar/other_thing',
    '/controller/baz/a'           => 'got autoloaded method a for baz',
    '/controller/baz/foo'         => '/baz/foo',
    '/action/foo'                 => 'GET on foo',
    '/action/bar'                 => 'any method on bar',
    '/action/specific'            => 'specific GET',
    'POST:/action/specific'       => 'specific POST',
    'PUT:/action/specific'        => 'specific any method',
);

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        for my $r (keys %expected) {
            my $meth = 'GET';
            my $path = $r;
            if ($path =~ s/^(.*)://) {
                $meth = $1;
            }
            my $req = HTTP::Request->new($meth => "http://localhost$path");
            my $res = $cb->($req);
            is($res->content, $expected{$r},
               "right content for $meth $path");
        }
    };

done_testing;
