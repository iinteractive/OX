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
}

{
    package Bar::Controller;
    use Moose;

    sub index          { "index for bar" }
    sub thing          { "/bar/thing" }
    sub other_thing    { "/bar/other_thing" }
    sub specific_thing { "specific thing for bar" }
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
    package Foo;
    use OX;
    use Moose::Util::TypeConstraints qw(enum);

    component Foo => 'Foo::Controller';
    component Bar => 'Bar::Controller';
    component Baz => 'Baz::Controller';

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

    }, (foo => depends_on('Component/Foo'),
        bar => depends_on('Component/Bar'),
        baz => depends_on('Component/Baz'));
}

my %expected = (
    '/foo/foo'                    => '/foo/foo',
    '/foo/bar'                    => '/foo/bar',
    '/foo/specific'               => 'got a specific path under /foo',
    # XXX: this seems odd, but i guess it's just Path::Router behavior
    '/bar/thing'                  => 'got thing for bar',
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
);

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        for my $path (keys %expected) {
            my $req = HTTP::Request->new(GET => "http://localhost$path");
            my $res = $cb->($req);
            is($res->content, $expected{$path},
               "right content for $path");
        }
    };

done_testing;
