#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Moose;
use Test::Path::Router;
use Plack::Test;
use HTTP::Request::Common;

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
    /guestbook.html
    /guestbook.json
];

routes_ok($router, {
    'guestbook.html' => { resource => 'guestbook', transform => 'html' },
    'guestbook.json' => { resource => 'guestbook', transform => 'json' },
},
"... our routes are valid");

my $title = qr/<title>OX - Guestbook Example<\/title>/;

test_psgi
      app    => $app->to_app,
      client => sub {
          my $cb = shift;
          {
              my $req = GET "http://localhost/guestbook.html";
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<div id="posts"><\/div>/, '... got the right content in guestbook.html');
          }
          {
              my $req = GET "http://localhost/guestbook.json";
              my $res = $cb->($req);
              is($res->content, '[]', '... got the right content in guestbook.json');
          }
          {
              my $req = POST "http://localhost/guestbook.html", [ note => 'Hello World' ];
              my $res = $cb->($req);
              is($res->code, 302, '... got redirection status code');
          }
          {
              my $req = GET "http://localhost/guestbook.html";
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<div id="posts"><div class="post">Hello World<\/div><\/div>/, '... got the right content in index');
          }
          {
              my $req = GET "http://localhost/guestbook.json";
              my $res = $cb->($req);
              is($res->content, '["Hello World"]', '... got the right content in guestbook.json');
          }
          {
              my $req = POST "http://localhost/guestbook.json", [ note => 'Goodbye World' ];
              my $res = $cb->($req);
              is($res->code, 302, '... got redirection status code');
          }
          {
              my $req = GET "http://localhost/guestbook.json";
              my $res = $cb->($req);
              is($res->content, '["Hello World","Goodbye World"]', '... got the right content in guestbook.json');
          }
      };

done_testing;



