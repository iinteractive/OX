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
        wrap sub {
            my $app = shift;
            return sub {
                my $res = $app->($_[0]);
                $res->[2][0] .= " wrapped";
                return $res;
            };
        };

        route '/'    => sub { "base" };
        route '/foo' => sub { "base foo" };
    };
}

{
    package MyApp2;
    use OX;

    extends 'MyApp';

    router as {
        wrap sub {
            my $app = shift;
            return sub {
                my $res = $app->($_[0]);
                $res->[2][0] = uc($res->[2][0]);
                return $res;
            };
        };

        route '/'    => sub { "subclass" };
        route '/bar' => sub { "subclass bar" };
    }
}

test_psgi
    app => MyApp2->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, 'SUBCLASS WRAPPED');
        }

        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, 'BASE FOO WRAPPED');
        }

        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, 'SUBCLASS BAR WRAPPED');
        }
    };

{
    package MyApp3;
    use OX;

    extends 'MyApp2';

    router as {
        wrap sub {
            my $app = shift;
            return sub {
                my $res = $app->($_[0]);
                $res->[2][0] = "outerA-" . $res->[2][0];
                return $res;
            };
        };
        wrap sub {
            my $app = shift;
            return sub {
                my $res = $app->($_[0]);
                $res->[2][0] =~ s/A/?/g;
                return $res;
            };
        };

        route '/'    => sub { "subsubclass" };
        route '/baz' => sub { "subsubclass baz" };
    }
}

test_psgi
    app => MyApp3->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, 'outerA-SUBSUBCL?SS WR?PPED');
        }

        {
            my $res = $cb->(GET '/foo');
            ok($res->is_success);
            is($res->content, 'outerA-B?SE FOO WR?PPED');
        }

        {
            my $res = $cb->(GET '/bar');
            ok($res->is_success);
            is($res->content, 'outerA-SUBCL?SS B?R WR?PPED');
        }

        {
            my $res = $cb->(GET '/baz');
            ok($res->is_success);
            is($res->content, 'outerA-SUBSUBCL?SS B?Z WR?PPED');
        }
    };

done_testing;
