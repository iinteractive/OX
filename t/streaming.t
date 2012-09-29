#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use utf8;

{
    package MyApp::Controller;
    use Moose;

    sub basic {
        my $self = shift;
        my ($r) = @_;

        return sub {
            my $responder = shift;
            $responder->([ 200, [], ["hello world: " . $r->path] ]);
        }
    }

    sub writer {
        my $self = shift;
        my ($r) = @_;

        return sub {
            my $responder = shift;
            my $writer = $responder->([ 200, [] ]);
            $writer->write("hello world: ");
            $writer->write($r->path);
            $writer->close;
        }
    }

    sub utf8 {
        my $self = shift;
        my ($r) = @_;

        return sub {
            my $responder = shift;
            $responder->([ 200, [], ["café"] ]);
        }
    }

    sub latin1 {
        my $self = shift;
        my ($r) = @_;
        $r->encoding('latin1');

        return sub {
            my $responder = shift;
            $responder->([ 200, [], ["café"] ]);
        }
    }
}

{
    package MyApp;
    use OX;

    has controller => (
        is  => 'ro',
        isa => 'MyApp::Controller',
    );

    router as {
        route '/basic'  => 'controller.basic';
        route '/writer' => 'controller.writer';
        route '/utf8'   => 'controller.utf8';
        route '/latin1' => 'controller.latin1';
    };
}

test_psgi
    app => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $req = HTTP::Request->new(GET => "http://localhost/basic");
            my $res = $cb->($req);

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is($res->content, "hello world: /basic", "got the right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/writer");
            my $res = $cb->($req);

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is($res->content, "hello world: /writer", "got the right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/utf8");
            my $res = $cb->($req);

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is($res->content, "caf\xc3\xa9", "got the right content");
        }

        {
            my $req = HTTP::Request->new(GET => "http://localhost/latin1");
            my $res = $cb->($req);

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is($res->content, "caf\xe9", "got the right content");
        }
    };

done_testing;
