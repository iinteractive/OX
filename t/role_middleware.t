#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

BEGIN { plan skip_all => "i can't decide if this is a good idea or not" }

sub filter (&) {
    my $code = shift;
    return sub {
        my $app = shift;
        return sub {
            my $env = shift;
            my $res = $app->($env);
            $res->[2][0] = $code->($res->[2][0]);
            return $res;
        };
    };
}

{
    package MyApp::Role;
    use OX::Role;

    router as {
        wrap ::filter { "$_[0] MyApp::Role(1)" };
        wrap ::filter { "$_[0] MyApp::Role(2)" };

        route '/role' => sub { "role" };
    };
}

{
    package MyApp::Role2;
    use OX::Role;

    router as {
        wrap ::filter { "$_[0] MyApp::Role2(1)" };
        wrap ::filter { "$_[0] MyApp::Role2(2)" };

        route '/role2' => sub { "role2" };
    };

    with 'MyApp::Role';
}

{
    package MyApp;
    use OX;

    router as {
        wrap ::filter { "$_[0] MyApp(1)" };
        wrap ::filter { "$_[0] MyApp(2)" };

        route '/' => sub { "class" };
    };

    with 'MyApp::Role2';
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        my $middleware_id = 'MyApp::Role(2) MyApp::Role(1) MyApp::Role2(2) MyApp::Role2(1) MyApp(2) MyApp(1)';
        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "class $middleware_id");
        }

        {
            my $res = $cb->(GET '/role');
            ok($res->is_success);
            is($res->content, "role $middleware_id");
        }

        {
            my $res = $cb->(GET '/role2');
            ok($res->is_success);
            is($res->content, "role2 $middleware_id");
        }
    };

{
    package MyApp::Role3;
    use OX::Role;

    router as {
        wrap ::filter { "$_[0] MyApp::Role3(1)" };
        wrap ::filter { "$_[0] MyApp::Role3(2)" };

        route '/role3' => sub { "role3" };
    };
}

{
    package MyApp::Role4;
    use OX::Role;

    router as {
        wrap ::filter { "$_[0] MyApp::Role4(1)" };
        wrap ::filter { "$_[0] MyApp::Role4(2)" };

        route '/role4' => sub { "role4" };
    };
}

{
    package MyApp2;
    use OX;

    extends 'MyApp';

    router as {
        wrap ::filter { "$_[0] MyApp2(1)" };
        wrap ::filter { "$_[0] MyApp2(2)" };

        route '/' => sub { "class2" };
    };

    with 'MyApp::Role3', 'MyApp::Role4';
}

test_psgi
    app    => MyApp2->new->to_app,
    client => sub {
        my $cb = shift;

        my $middleware_id = 'MyApp::Role(2) MyApp::Role(1) MyApp::Role2(2) MyApp::Role2(1) MyApp(2) MyApp(1) MyApp::Role4(2) MyApp::Role4(1) MyApp::Role3(2) MyApp::Role3(1) MyApp2(2) MyApp2(1)';
        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "class2 $middleware_id");
        }

        {
            my $res = $cb->(GET '/role');
            ok($res->is_success);
            is($res->content, "role $middleware_id");
        }

        {
            my $res = $cb->(GET '/role2');
            ok($res->is_success);
            is($res->content, "role2 $middleware_id");
        }

        {
            my $res = $cb->(GET '/role3');
            ok($res->is_success);
            is($res->content, "role3 $middleware_id");
        }

        {
            my $res = $cb->(GET '/role4');
            ok($res->is_success);
            is($res->content, "role4 $middleware_id");
        }
    };

{
    package MyApp::Role5;
    use OX::Role;

    router as {
        wrap ::filter { "$_[0] MyApp::Role5(1)" };
        wrap ::filter { "$_[0] MyApp::Role5(2)" };

        route '/role5' => sub { "role5" };
    };
}

{
    my $app = MyApp2->new;
    Moose::Util::apply_all_roles($app, 'MyApp::Role5');
    test_psgi
        app    => $app->to_app,
        client => sub {
            my $cb = shift;

            my $middleware_id = 'MyApp::Role(2) MyApp::Role(1) MyApp::Role2(2) MyApp::Role2(1) MyApp(2) MyApp(1) MyApp::Role4(2) MyApp::Role4(1) MyApp::Role3(2) MyApp::Role3(1) MyApp2(2) MyApp2(1) MyApp::Role5(2) MyApp::Role5(1)';
            {
                my $res = $cb->(GET '/');
                ok($res->is_success);
                is($res->content, "class2 $middleware_id");
            }

            {
                my $res = $cb->(GET '/role');
                ok($res->is_success);
                is($res->content, "role $middleware_id");
            }

            {
                my $res = $cb->(GET '/role2');
                ok($res->is_success);
                is($res->content, "role2 $middleware_id");
            }

            {
                my $res = $cb->(GET '/role3');
                ok($res->is_success);
                is($res->content, "role3 $middleware_id");
            }

            {
                my $res = $cb->(GET '/role4');
                ok($res->is_success);
                is($res->content, "role4 $middleware_id");
            }

            {
                my $res = $cb->(GET '/role5');
                ok($res->is_success);
                is($res->content, "role5 $middleware_id");
            }
        };
}

done_testing;
