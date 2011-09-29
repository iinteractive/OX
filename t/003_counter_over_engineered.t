#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Path::Router;
use Plack::Test;
use Test::Requires 'Template', 'MooseX::Types::Path::Class', 'Path::Class';

BEGIN {
    use_ok('OX::Application');
}

use lib 't/apps/Counter-Over-Engineered/lib';

use Counter::Over::Engineered;

my $app = Counter::Over::Engineered->new;
isa_ok($app, 'Counter::Over::Engineered');
isa_ok($app, 'OX::Application');

#diag $app->_dump_bread_board;

my $root = $app->resolve( service => 'app_root' );
isa_ok($root, 'Path::Class::Dir');
is($root, 't/apps/Counter-Over-Engineered', '... got the right root dir');

my $router = $app->router;
isa_ok($router, 'Path::Router');

path_ok($router, $_, '... ' . $_ . ' is a valid path')
for qw[
    /
    /inc
    /dec
    /reset
    /set/10
];

routes_ok($router, {
    ''       => { controller => '/Controller/Root', action => 'index' },
    'inc'    => { controller => '/Controller/Root', action => 'inc'   },
    'dec'    => { controller => '/Controller/Root', action => 'dec'   },
    'reset'  => { controller => '/Controller/Root', action => 'reset' },
    'set/10' => { controller => '/Controller/Root', action => 'set',  number => 10 },
},
"... our routes are valid");

my $title = qr/<title>OX - Counter::Over::Engineered Example<\/title>/;

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
          {
              my $req = HTTP::Request->new(GET => "http://localhost/set/100");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>100<\/h1>/, '... got the right content in /set/100');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/dec");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>99<\/h1>/, '... got the right content in /dec');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/set/foo");
              my $res = $cb->($req);
              is($res->code, 404, '... did not match, so got 404');
          }
      };


done_testing;
