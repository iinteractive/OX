#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Path::Router;
use Plack::Test;
use Plack::Util;

sub test_counter {
    my ($res, $count) = @_;

    ok($res->is_success)
        || diag($res->status_line . "\n" . $res->content);

    my $content = $res->content;

    is($content, $count, "got the right content");
}

test_psgi
      app    => Plack::Util::load_psgi('t/apps/Counter-Tiny/scripts/app.psgi'),
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              test_counter($res, 0);
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              test_counter($res, 1);
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              test_counter($res, 2);
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/dec");
              my $res = $cb->($req);
              test_counter($res, 1);
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/reset");
              my $res = $cb->($req);
              test_counter($res, 0);
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              test_counter($res, 0);
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/set/23");
              my $res = $cb->($req);
              test_counter($res, 23);
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/set/foo");
              my $res = $cb->($req);
              is($res->code, 404, '... got the right status for invalid set');
          }
      };

done_testing;
