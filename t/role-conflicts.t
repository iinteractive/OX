#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Plack::Test;

use HTTP::Request::Common;

{
    package MyApp::Role1;
    use OX::Role;

    router as {
        route '/foo' => sub { "foo" };
        route '/bar' => sub { "bar" };
    };
}

{
    package MyApp::Role2;
    use OX::Role;

    router as {
        route '/foo' => sub { "FOO" };
        route '/baz' => sub { "BAZ" };
    };
}

{
    package MyApp::Conflict;
    use OX;

    ::like(
        ::exception { with 'MyApp::Role1', 'MyApp::Role2' },
        qr{conflict.*/foo}i,
    );
}

{
    package MyApp::NoConflict;
    use OX;

    router as {
        route '/foo' => sub { "resolved" };
    };

    with 'MyApp::Role1', 'MyApp::Role2';
}

test_psgi
    app    => MyApp::NoConflict->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, 'resolved');
        }
        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, 'bar');
        }
        {
            my $res = $cb->(GET '/baz');
            ok($res->is_success);
            is($res->content, 'BAZ');
        }
    };

done_testing;
