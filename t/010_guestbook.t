#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Moose;
use Test::Path::Router;
use Plack::Test;

BEGIN {
    use_ok('OX::Application');
}

use lib 't/apps/Guestbook/lib';

use Guestbook;

my $app = Guestbook->new;
isa_ok($app, 'Guestbook');
isa_ok($app, 'OX::Application');

# diag $app->_dump_bread_board;

my $root = $app->fetch_service('app_root');
isa_ok($root, 'Path::Class::Dir');
is($root, 't/apps/Guestbook', '... got the right root dir');

my $router = $app->fetch_service('Router');
isa_ok($router, 'Path::Router');

path_ok($router, $_, '... ' . $_ . ' is a valid path')
for qw[
    /
    /list
    /post
];

routes_ok($router, {
    ''     => { controller => 'root', action => 'index' },
    'list' => { controller => 'root', action => 'list' },
    'post' => { controller => 'root', action => 'post' },
},
"... our routes are valid");

my $title = qr/<title>OX - Guestbook Example<\/title>/;

test_psgi
      app    => $app->to_app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/");
              my $res = $cb->($req);
              is($res->code, 302, '... got redirection status code');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/list");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<div id="posts"><\/div>/, '... got the right content in index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/post?text=Hello%20World");
              my $res = $cb->($req);
              is($res->code, 302, '... got redirection status code');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/list");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<div id="posts"><div class="post">Hello World<\/div><\/div>/, '... got the right content in index');
          }
      };

done_testing;



