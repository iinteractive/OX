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

{
    package MyApp2::Role1;
    use OX::Role;

    router as {
        route '/foo/:a' => sub { "foo: $_[1] " . $_[0]->mapping->{a} };
        route '/bar/:b' => sub { "bar: $_[1] " . $_[0]->mapping->{b} };
    };
}

{
    package MyApp2::Role2;
    use OX::Role;

    router as {
        route '/foo/:c' => sub { "FOO: $_[1] " . $_[0]->mapping->{c} };
        route '/baz/:d' => sub { "BAZ: $_[1] " . $_[0]->mapping->{d} };
    };
}

{
    package MyApp2::Conflict;
    use OX;

    ::like(
        ::exception { with 'MyApp2::Role1', 'MyApp2::Role2' },
        qr{conflict.*(?:/foo/:a.*/foo/:c|/foo/:c.*/foo/:a)}i,
    );
}

{
    package MyApp2::NoConflict;
    use OX;

    router as {
        route '/foo/:e' => sub { "resolved: $_[1] " . $_[0]->mapping->{e} };
    };

    with 'MyApp2::Role1', 'MyApp2::Role2';
}

test_psgi
    app    => MyApp2::NoConflict->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/foo/20');
            ok($res->is_success);
            is($res->content, 'resolved: 20 20');
        }
        {
            my $res = $cb->(GET '/bar/21');
            ok($res->is_success);
            is($res->content, 'bar: 21 21');
        }
        {
            my $res = $cb->(GET '/baz/22');
            ok($res->is_success);
            is($res->content, 'BAZ: 22 22');
        }
    };

{
    package MyApp::Mounts::Role1;
    use OX::Role;

    router as {
        mount '/foo' => sub { [ 200, [], ["foo"] ] };
        mount '/bar' => sub { [ 200, [], ["bar"] ] };
    };
}

{
    package MyApp::Mounts::Role2;
    use OX::Role;

    router as {
        mount '/foo' => sub { [ 200, [], ["FOO"] ] };
        mount '/baz' => sub { [ 200, [], ["BAZ"] ] };
    };
}

{
    package MyApp::Mounts::Conflict;
    use OX;

    ::like(
        ::exception { with 'MyApp::Mounts::Role1', 'MyApp::Mounts::Role2' },
        qr{conflict.*/foo}i,
    );
}

{
    package MyApp::Mounts::NoConflict;
    use OX;

    router as {
        mount '/foo' => sub { [ 200, [], ["resolved"] ] };
    };

    with 'MyApp::Mounts::Role1', 'MyApp::Mounts::Role2';
}

test_psgi
    app    => MyApp::Mounts::NoConflict->new->to_app,
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

{
    package MyApp::Mixed::Role1;
    use OX::Role;

    router as {
        mount '/foo' => sub { [ 200, [], ["foo"] ] };
        mount '/bar' => sub { [ 200, [], ["bar"] ] };
    };
}

{
    package MyApp::Mixed::Role2;
    use OX::Role;

    router as {
        route '/foo' => sub { "FOO" };
        route '/baz' => sub { "BAZ" };
    };
}

{
    package MyApp::Mixed::Conflict;
    use OX;

    ::like(
        ::exception { with 'MyApp::Mixed::Role1', 'MyApp::Mixed::Role2' },
        qr{conflict.*/foo}i,
    );
}

{
    package MyApp::Mixed::NoResolution;
    use OX;

    router as {
        mount '/foo' => sub { [ 200, [], ["resolved"] ] };
    };

    ::like(
        ::exception { with 'MyApp::Mixed::Role1', 'MyApp::Mixed::Role2' },
        qr{conflict.*/foo}i,
    );
}

{
    package MyApp::Mixed::NoResolution2;
    use OX;

    router as {
        route '/foo' => sub { "resolved" };
    };

    ::like(
        ::exception { with 'MyApp::Mixed::Role1', 'MyApp::Mixed::Role2' },
        qr{conflict.*/foo}i,
    );
}

{
    package MyApp::Mixed2::Role1;
    use OX::Role;

    router as {
        mount '/foo' => sub { [ 200, [], ["foo"] ] };
        mount '/bar' => sub { [ 200, [], ["bar"] ] };
    };
}

{
    package MyApp::Mixed2::Role2;
    use OX::Role;

    router as {
        route '/foo/thing' => sub { "FOO" };
        route '/baz'       => sub { "BAZ" };
    };
}

{
    package MyApp::Mixed2::Conflict;
    use OX;

    ::like(
        ::exception { with 'MyApp::Mixed2::Role1', 'MyApp::Mixed2::Role2' },
        qr{conflict.*(?:/foo/thing.*/foo|/foo.*/foo/thing)}i,
    );
}

{
    package MyApp::Mixed2::NoResolution;
    use OX;

    router as {
        mount '/foo' => sub { [ 200, [], ["resolved"] ] };
    };

    ::like(
        ::exception { with 'MyApp::Mixed2::Role1', 'MyApp::Mixed2::Role2' },
        qr{conflict.*(?:/foo/thing.*/foo|/foo.*/foo/thing)}i,
    );
}

{
    package MyApp::Mixed2::NoResolution2;
    use OX;

    router as {
        route '/foo' => sub { "resolved" };
    };

    ::like(
        ::exception { with 'MyApp::Mixed2::Role1', 'MyApp::Mixed2::Role2' },
        qr{conflict.*(?:/foo/thing.*/foo|/foo.*/foo/thing)}i,
    );
}

{
    package MyApp::Mixed2::NoResolution3;
    use OX;

    router as {
        route '/foo/thing' => sub { "resolved" };
    };

    ::like(
        ::exception { with 'MyApp::Mixed2::Role1', 'MyApp::Mixed2::Role2' },
        qr{conflict.*(?:/foo/thing.*/foo|/foo.*/foo/thing)}i,
    );
}

done_testing;
