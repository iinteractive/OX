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
        my ($r, $content) = @_;

        return "got $content from path " . $r->path
             . " (" . join(' ', sort keys %{ $r->mapping }) . ")";
    }
}

{
    package MyApp::Controller;
    use Moose;

    has view => (
        is       => 'ro',
        isa      => 'MyApp::View',
        required => 1,
        handles  => ['render'],
    );
}

{
    package MyApp::Controller::Root;
    use Moose;

    extends 'MyApp::Controller';

    sub index {
        my $self = shift;
        my ($r) = @_;

        return $self->render($r, "main index");
    }
}

{
    package MyApp::Controller::Posts;
    use Moose;

    extends 'MyApp::Controller';

    sub show {
        my $self = shift;
        my ($r, $id) = @_;

        return $self->render($r, "post $id");
    }
}

{
    package MyApp::Role::Posts;
    use OX::Role;

    has posts => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Posts',
        infer => 1,
    );

    router as {
        route '/post/:id' => 'posts.show';
        mount '/auth'     => sub { [ 200, [], ["auth: $_[0]->{PATH_INFO}"] ] };
    };
}

{
    package MyApp;
    use OX;

    with 'MyApp::Role::Posts';

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    router as {
        route '/' => 'root.index';
    };
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "got main index from path / (action controller)");
        }

        {
            my $res = $cb->(GET '/post/32');
            ok($res->is_success);
            is($res->content, "got post 32 from path /post/32 (action controller id)");
        }

        {
            my $res = $cb->(GET '/auth/login');
            ok($res->is_success);
            is($res->content, "auth: /login");
        }
    };

{
    package MyApp2;
    use OX;

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    router as {
        route '/post/:id' => 'root.index';
    };

    with 'MyApp::Role::Posts';
}

test_psgi
    app    => MyApp2->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/post/32');
            ok($res->is_success);
            is($res->content, "got main index from path /post/32 (action controller id)");
        }
    };

{
    package MyApp3;
    use OX;

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    has root => (
        is    => 'ro',
        isa   => 'MyApp::Controller::Root',
        infer => 1,
    );

    router as {
        route '/post/:number' => 'root.index';
    };

    with 'MyApp::Role::Posts';
}

test_psgi
    app    => MyApp3->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/post/32');
            ok($res->is_success);
            is($res->content, "got main index from path /post/32 (action controller number)");
        }
    };

done_testing;
