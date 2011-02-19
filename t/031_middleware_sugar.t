#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo;
    use OX;

    router as {
        wrap sub {
            my $app = shift;
            return sub {
                my $env = shift;
                $env->{'test.foo'} = 'FOO';
                $app->($env);
            };
        };

        route '/' => sub {
            my $req = shift;
            $req->env->{'test.foo'};
        };
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'FOO', "got the right content");
        }
    };

done_testing;
