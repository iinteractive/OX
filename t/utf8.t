#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use utf8;

{
    package Foo::Controller;
    use Moose;

    sub query {
        my $self = shift;
        my ($r) = @_;

        my $got = $r->param("query");
        ::ok(utf8::is_utf8($got), "query param is encoded");
        ::is($got, "café", "got the correct query param value");

        return "déjà vu";
    }

    sub body {
        my $self = shift;
        my ($r) = @_;

        my $got = $r->param("body");
        ::ok(utf8::is_utf8($got), "body param is encoded");
        ::is($got, "café", "got the correct body param value");

        return "déjà vu";
    }

    sub content {
        my $self = shift;
        my ($r) = @_;

        my $got = $r->content;
        ::ok(utf8::is_utf8($got), "content is encoded");
        ::is($got, "出国まで四日間だけか", "body content encoded correctly");

        return "インド料理を食い過ぎた。うめええ";
    }

    sub binary {
        my $self = shift;
        my ($r) = @_;

        $r->encoding(undef);
        return "\x01\x02\x03\x04\xf3";
    }
}

{
    package Foo;
    use OX;

    has controller => (
        is  => 'ro',
        isa => 'Foo::Controller',
    );

    router as {
        route '/query'   => 'controller.query';
        route '/body'    => 'controller.body';
        route '/content' => 'controller.content';
        route '/binary'  => 'controller.binary';
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(
                GET => 'http://localhost/query?query=caf%C3%A9'
            );
            my $res = $cb->($req);
            my $content = $res->content;
            like($content, qr/^[\x00-\xff]*$/, "raw content is in bytes");
            my $expected = "déjà vu";
            utf8::encode($expected);
            is($content, $expected, "got utf8 bytes");
        }
        {
            my $req = HTTP::Request->new(
                POST => 'http://localhost/body',
                ['Content-Type' => 'application/x-www-form-urlencoded'],
                'body=caf%C3%A9'
            );
            my $res = $cb->($req);
            my $content = $res->content;
            like($content, qr/^[\x00-\xff]*$/, "raw content is in bytes");
            my $expected = "déjà vu";
            utf8::encode($expected);
            is($content, $expected, "got utf8 bytes");
        }
        {
            my $body = '出国まで四日間だけか';
            utf8::encode($body);
            my $req = HTTP::Request->new(
                POST => 'http://localhost/content',
                ['Content-Type' => 'text/plain'],
                $body
            );
            my $res = $cb->($req);
            my $content = $res->content;
            like($content, qr/^[\x00-\xff]*$/, "raw content is in bytes");
            my $expected = "インド料理を食い過ぎた。うめええ";
            utf8::encode($expected);
            is($content, $expected, "got utf8 bytes");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/binary');
            my $res = $cb->($req);
            my $content = $res->content;
            like($content, qr/^[\x00-\xff]*$/, "raw content is in bytes");
            is($content, "\x01\x02\x03\x04\xf3", "got raw bytes");
        }
    };

{
    package UnicodeArgs;
    use OX;

    router as {
        route '/:str' => sub {
            my ($req, $str) = @_;
            return [ 200, ['Content-Type' => 'text/plain'], ["got $str"] ];
        }
    };
}

test_psgi
    app    => UnicodeArgs->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/יאדנאמאד');
            my $content = $res->decoded_content;
            is($content, "got יאדנאמאד");
        }
    };

done_testing;
