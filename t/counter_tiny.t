#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Path::Router;
use Plack::Test;
use Plack::Util;

test_psgi
      app    => Plack::Util::load_psgi('t/apps/Counter-Tiny/scripts/app.psgi'),
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              is($res->content, '0', '... got the right content in index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              is($res->content, '1', '... got the right content in /inc');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              is($res->content, '2', '... got the right content in /inc');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/dec");
              my $res = $cb->($req);
              is($res->content, '1', '... got the right content in /dec');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/reset");
              my $res = $cb->($req);
              is($res->content, '0', '... got the right content in /reset');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              is($res->content, '0', '... got the right content in index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/set/23");
              my $res = $cb->($req);
              is($res->content, '23', '... got the right content in set');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/set/foo");
              my $res = $cb->($req);
              is($res->code, 404, '... got the right status for invalid set');
          }
      };

done_testing;
