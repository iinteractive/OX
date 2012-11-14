#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

{
    package MyApp;
    use OX;

    router as {
        wrap_if sub { ($_[0]->{HTTP_X_FOO} || '') =~ /Bar/i },
            'Plack::Middleware::XFramework' => (
                framework => literal('Testing'),
            );
        wrap_if sub { $_[0]->{HTTP_X_ALLCAPS} },
            sub {
                my $app = shift;
                sub {
                    my $res = $app->($_[0]);
                    $res->[2] = [ map uc $_, @{$res->[2]} ];
                    $res
                };
            };

        route '/' => sub {
            return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello' ] ]
        };
    };
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET 'http://localhost/');
            ok($res->is_success);
            ok(!$res->header('X-Framework'));
            is($res->content, 'Hello');
        }
        {
            my $res = $cb->(GET 'http://localhost/', 'X-Foo' => 'Bar');
            ok($res->is_success);
            like($res->header('X-Framework'), qr/Testing/);
            is($res->content, 'Hello');
        }
        {
            my $res = $cb->(GET 'http://localhost/', 'X-AllCaps' => 1);
            ok($res->is_success);
            ok(!$res->header('X-Framework'));
            is($res->content, 'HELLO');
        }
    };

done_testing;
