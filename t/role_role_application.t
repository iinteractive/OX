#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

{
    package MyApp::View;
    use Moose;

    sub render {
        my $self = shift;
        my ($r, $str) = @_;

        return "$str from " . $r->path;
    }
}

{
    package MyApp::Controller::Auth;
    use Moose;

    has view => (
        is       => 'ro',
        isa      => 'MyApp::View',
        required => 1,
        handles  => ['render'],
    );

    sub login {
        my $self = shift;
        my ($r) = @_;

        return $self->render($r, "login");
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
        my ($r) = @_;

        return $self->render($r, "main index");
    }
}

{
    package MyOtherApp;
    use OX;

    router as {
        route '/' => sub { "other app" };
    };
}

{
    package MyApp::Role::Auth;
    use OX::Role;

    has auth => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Auth',
        infer => 1,
    );

    router as {
        route '/login' => 'auth.login';
        mount '/otherapp' => 'MyOtherApp';
    };
}

{
    package MyApp::Role::Root;
    use OX::Role;

    with 'MyApp::Role::Auth';

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    router as {
        route '/' => 'root.index';
    };
}

{
    package MyApp;
    use OX;

    with 'MyApp::Role::Root';

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "main index from /");
        }
        {
            my $res = $cb->(GET '/login');
            ok($res->is_success);
            is($res->content, "login from /login");
        }
        {
            my $res = $cb->(GET '/otherapp');
            ok($res->is_success);
            is($res->content, "other app");
        }
    };

done_testing;
