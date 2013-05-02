#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

{

    package Foo;
    use OX;

    router as {

        # controller action
        route '/controller_action' => 'root.index';

        # http method
        route '/http_method' => 'root_index';
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/controller_action');
            is($res->code, 500, "without controller from route spec we got Internal Server Error");
            like($res->content, qr/^Cannot resolve root in Foo: Could not find container or service for root in Foo/, "got the right content" );
        }

        {
            my $res = $cb->(GET '/http_method');
            is($res->code, 500, "without controller from route spec we got Internal Server Error");
            like($res->content, qr/^Cannot resolve root_index in Foo: Could not find container or service for root_index in Foo/, "got the right content" );
        }
    };

done_testing;
