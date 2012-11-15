#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Plack::Test;

use HTTP::Request::Common;

{
    package MyApp;
    use OX;

    router as {
        route '/' => sub { "root" };
        mount '/foo' => router as {
            route '/' => sub { "foo root" };
            route '/bar' => sub { "foo bar" };
        };
    };
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "root");
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "foo root");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "foo bar");
        }
        {
            my $res = $cb->(GET '/foo/baz');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/bar');
            ok(!$res->is_success);
            is($res->code, 404);
        }
    };

{
    package MyApp2;
    use OX;

    router as {
        mount '/foo' => router as {
            route '/' => sub { "foo root" };
            mount '/bar' => router as {
                route '/'    => sub { "foo bar" };
                route '/baz' => sub { "foo bar baz" };
            };
        };
        mount '/bar' => router as {
            route '/'    => sub { "BAR ROOT" };
            route '/baz' => sub { "BAR BAZ" };
        };
    };
}

test_psgi
    app    => MyApp2->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "foo root");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "foo bar");
        }
        {
            my $res = $cb->(GET '/foo/baz');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/foo/bar/baz');
            ok($res->is_success);
            is($res->content, "foo bar baz");
        }
        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, "BAR ROOT");
        }
        {
            my $res = $cb->(GET '/bar/baz');
            ok($res->is_success);
            is($res->content, "BAR BAZ");
        }
        {
            my $res = $cb->(GET '/baz');
            ok(!$res->is_success);
            is($res->code, 404);
        }
    };

{
    package My::Custom::RouteBuilder1;
    use Moose;
    with 'OX::RouteBuilder';

    sub compile_routes {
        my $self = shift;

        my ($defaults, $validations) = $self->extract_defaults_and_validations($self->params);

        return {
            path        => $self->path,
            defaults    => $defaults,
            target      => $self->route_spec,
            validations => $validations,
        };
    }

    sub parse_action_spec {
        my $class = shift;
        my ($action_spec) = @_;

        return unless $action_spec =~ s/^custom1://;
        return sub { $action_spec };
    }
}

{
    package My::Custom::RouteBuilder2;
    use Moose;
    with 'OX::RouteBuilder';

    sub compile_routes {
        my $self = shift;

        my ($defaults, $validations) = $self->extract_defaults_and_validations($self->params);

        return {
            path        => $self->path,
            defaults    => $defaults,
            target      => $self->route_spec,
            validations => $validations,
        };
    }

    sub parse_action_spec {
        my $class = shift;
        my ($action_spec) = @_;

        return unless $action_spec =~ s/^custom2://;
        return sub { $action_spec };
    }
}


{
    package MyApp3;
    use OX;

    router ['My::Custom::RouteBuilder1'], as {
        route '/' => "custom1:index";
        ::like(
            ::exception { route '/error' => 'custom2:error' },
            qr/Unknown action spec custom2:error/,
        );
        ::like(
            ::exception { route '/error2' => sub { "error2" } },
            qr/Unknown action spec CODE/,
        );
        mount '/foo' => router as {
            route '/' => "custom1:foo_index";
            ::like(
                ::exception { route '/error' => 'custom2:error' },
                qr/Unknown action spec custom2:error/,
            );
            ::like(
                ::exception { route '/error2' => sub { "error2" } },
                qr/Unknown action spec CODE/,
            );
        };
        mount '/bar' => router ['My::Custom::RouteBuilder2'], as {
            route '/' => "custom2:bar_index";
            ::like(
                ::exception { route '/error' => 'custom1:error' },
                qr/Unknown action spec custom1:error/,
            );
            ::like(
                ::exception { route '/error2' => sub { "error2" } },
                qr/Unknown action spec CODE/,
            );
        };
    };
}

test_psgi
    app => MyApp3->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "index");
        }
        {
            my $res = $cb->(GET '/error');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/error2');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "foo_index");
        }
        {
            my $res = $cb->(GET '/foo/error');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/foo/error2');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, "bar_index");
        }
        {
            my $res = $cb->(GET '/bar/error');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/bar/error2');
            ok(!$res->is_success);
            is($res->code, 404);
        }
    };

{
    package MyApp::View;
    use Moose;

    sub render {
        my $self = shift;
        my ($content) = @_;

        return "rendered $content";
    }
}

{
    package MyApp::Controller::Root;
    use Moose;

    has view => (
        is       => 'ro',
        isa      => 'MyApp::View',
        required => 1,
        handles  => ['render'],
    );

    sub index {
        my $self = shift;

        return $self->render("root index");
    }

    sub baz {
        my $self = shift;

        return $self->render("root baz");
    }

    sub fallback {
        my $self = shift;
        my ($r) = @_;

        return $self->render("fallback for " . $r->path);
    }
}

{
    package MyApp::Controller::Foo;
    use Moose;

    has view => (
        is       => 'ro',
        isa      => 'MyApp::View',
        required => 1,
        handles  => ['render'],
    );

    sub index {
        my $self = shift;

        return $self->render("foo index");
    }

    sub bar {
        my $self = shift;

        return $self->render("foo bar");
    }
}

{
    package MyApp4;
    use OX;

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    has foo => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Foo',
        infer => 1,
    );

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    router as {
        route '/'    => 'root.index';
        route '/baz' => 'root.baz';
        route '/:_'  => 'root.fallback';
        mount '/foo' => router as {
            route '/'    => 'foo.index';
            route '/bar' => 'foo.bar';
            route '/:_'  => 'root.fallback';
        };
    }
}

test_psgi
    app    => MyApp4->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "rendered root index");
        }
        {
            my $res = $cb->(GET '/baz');
            ok($res->is_success);
            is($res->content, "rendered root baz");
        }
        {
            my $res = $cb->(GET '/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "rendered foo index");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "rendered foo bar");
        }
        {
            my $res = $cb->(GET '/foo/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
    };

{
    package MyApp5::Role;
    use OX::Role;

    router as {
        mount '/foo' => router as {
            route '/' => sub { "foo root" };
            mount '/bar' => router as {
                route '/'    => sub { "foo bar" };
                route '/baz' => sub { "foo bar baz" };
            };
        };
        mount '/bar' => router as {
            route '/'    => sub { "BAR ROOT" };
            route '/baz' => sub { "BAR BAZ" };
        };
    }
}

{
    package MyApp5;
    use OX;

    with 'MyApp5::Role';
}

test_psgi
    app    => MyApp5->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "foo root");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "foo bar");
        }
        {
            my $res = $cb->(GET '/foo/baz');
            ok(!$res->is_success);
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/foo/bar/baz');
            ok($res->is_success);
            is($res->content, "foo bar baz");
        }
        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, "BAR ROOT");
        }
        {
            my $res = $cb->(GET '/bar/baz');
            ok($res->is_success);
            is($res->content, "BAR BAZ");
        }
        {
            my $res = $cb->(GET '/baz');
            ok(!$res->is_success);
            is($res->code, 404);
        }
    };

{
    package MyApp6::Role;
    use OX::Role;

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    has foo => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Foo',
        infer => 1,
    );

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    router as {
        route '/'    => 'root.index';
        route '/baz' => 'root.baz';
        route '/:_'  => 'root.fallback';
        mount '/foo' => router as {
            route '/'    => 'foo.index';
            route '/bar' => 'foo.bar';
            route '/:_'  => 'root.fallback';
        };
    }
}

{
    package MyApp6;
    use OX;

    with 'MyApp6::Role';
}

test_psgi
    app    => MyApp6->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "rendered root index");
        }
        {
            my $res = $cb->(GET '/baz');
            ok($res->is_success);
            is($res->content, "rendered root baz");
        }
        {
            my $res = $cb->(GET '/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "rendered foo index");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "rendered foo bar");
        }
        {
            my $res = $cb->(GET '/foo/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
    };

{
    package MyApp7::Super;
    use OX;

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    router as {
        route '/'    => 'root.index';
        route '/baz' => 'root.baz';
        route '/:_'  => 'root.fallback';
    };
}

{
    package MyApp7;
    use OX;

    extends 'MyApp7::Super';

    has foo => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Foo',
        infer => 1,
    );

    router as {
        mount '/foo' => router as {
            route '/'    => 'foo.index';
            route '/bar' => 'foo.bar';
            route '/:_'  => 'root.fallback';
        };
    }
}

test_psgi
    app    => MyApp7->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "rendered root index");
        }
        {
            my $res = $cb->(GET '/baz');
            ok($res->is_success);
            is($res->content, "rendered root baz");
        }
        {
            my $res = $cb->(GET '/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "rendered foo index");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "rendered foo bar");
        }
        {
            my $res = $cb->(GET '/foo/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
    };

{
    package MyApp8::Super;
    use OX;

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    router as {
        route '/'    => 'root.index';
        route '/baz' => 'root.baz';
        route '/:_'  => 'root.fallback';
    };
}

{
    package MyApp8::Role;
    use OX::Role;

    has foo => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Foo',
        infer => 1,
    );

    router as {
        mount '/foo' => router as {
            route '/'    => 'foo.index';
            route '/bar' => 'foo.bar';
            route '/:_'  => 'root.fallback';
        };
    }
}

{
    package MyApp8;
    use OX;

    extends 'MyApp8::Super';
    with 'MyApp8::Role';
}

test_psgi
    app    => MyApp8->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "rendered root index");
        }
        {
            my $res = $cb->(GET '/baz');
            ok($res->is_success);
            is($res->content, "rendered root baz");
        }
        {
            my $res = $cb->(GET '/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, "rendered foo index");
        }
        {
            my $res = $cb->(GET '/foo/bar');
            ok($res->is_success);
            is($res->content, "rendered foo bar");
        }
        {
            local $TODO = "nested routers can currently only access services in the role they are defined in";
            my $res = $cb->(GET '/foo/quux');
            ok($res->is_success);
            is($res->content, "rendered fallback for /quux");
        }
    };

done_testing;
