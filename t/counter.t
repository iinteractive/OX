#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Path::Router;
use Plack::Test;

BEGIN {
    use_ok('OX::Application');
}

use lib 't/apps/Counter/lib';

use Counter;

my $app = Counter->new;
isa_ok($app, 'Counter');
isa_ok($app, 'OX::Application');

# diag $app->_dump_bread_board;

my $router = $app->router;
isa_ok($router, 'Path::Router');

path_ok($router, $_, '... ' . $_ . ' is a valid path')
for qw[
    /
    /inc
    /dec
    /reset
];

routes_ok($router, {
    ''      => { page => 'index' },
    'inc'   => { page => 'inc'   },
    'dec'   => { page => 'dec'   },
    'reset' => { page => 'reset' },
},
"... our routes are valid");

my $title = qr/<title>OX - Counter Example<\/title>/;

test_psgi
      app    => $app->to_app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>0<\/h1>/, '... got the right content in index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>1<\/h1>/, '... got the right content in /inc');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>2<\/h1>/, '... got the right content in /inc');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/dec");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>1<\/h1>/, '... got the right content in /dec');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/reset");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>0<\/h1>/, '... got the right content in /reset');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>0<\/h1>/, '... got the right content in index');
          }
      };

done_testing;
