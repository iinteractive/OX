#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $warnings;
$SIG{__WARN__} = sub { $warnings .= $_[0] };

$warnings = '';
{
    package MyApp;
    use OX;

    router as {
        mount '/' => sub { };
        route '/foo' => sub { };
    };
}

like($warnings, qr{^The application mounted at / will shadow the route declared at /foo[^\n]*\n$}, "got the right warning");

$warnings = '';
{
    package MyApp2;
    use OX;

    router as {
        route '/foo' => sub { };
        mount '/' => sub { };
    };
}

like($warnings, qr{^The application mounted at / will shadow the route declared at /foo[^\n]*\n$}, "got the right warning");

$warnings = '';
{
    package MyApp3;
    use OX;

    router as {
        mount '/bar' => sub { };
        route '/bar/quux' => sub { };
        route '/foo/bar' => sub { };
        route '/foo/baz/quux' => sub { };
        mount '/foo' => sub { };
    };
}

like($warnings, qr{^The application mounted at /bar will shadow the route declared at /bar/quux[^\n]*\nThe application mounted at /foo will shadow the route declared at /foo/bar[^\n]*\nThe application mounted at /foo will shadow the route declared at /foo/baz/quux[^\n]*\n$}, "got the right warning");

{
    package MyApp4;
    use OX;

    router as {
        route '/foo' => sub { };
    };
    ::like(
        ::exception {
            router as {
                route '/bar' => sub { };
            };
        },
        qr/^Only one top level router is allowed/
    );
}

done_testing;
