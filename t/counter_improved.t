#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Path::Router;
use Plack::Test;
use Test::Requires 'Template', 'MooseX::Types::Path::Class', 'Path::Class';
use Path::Class;

BEGIN {
    use_ok('OX::Application');
}

use lib 't/apps/Counter-Improved/lib';

use Counter::Improved;

my $app = Counter::Improved->new;
isa_ok($app, 'Counter::Improved');
isa_ok($app, 'OX::Application');

#diag $app->_dump_bread_board;

my $root = $app->resolve( service => 'app_root' );
isa_ok($root, 'Path::Class::Dir');
is($root, file('t', 'apps', 'Counter-Improved')->stringify,
   '... got the right root dir');

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

sub test_counter {
    my ($res, $count) = @_;

    ok($res->is_success)
        || diag($res->status_line . "\n" . $res->content);

    my $content = $res->content;

    like(
        $content,
        qr/<title>OX - Counter::Improved Example<\/title>/,
        "got the right title"
    );
    like(
        $content,
        qr/<h1>$count<\/h1>/,
        "got the right count"
    );

    my @paths = (
        '/inc',
        '/dec',
        '/reset',
    );

    for my $path (@paths) {
        like(
            $content,
            qr{<a href="$path">},
            "link to $path exists"
        );
    }
}

test_psgi
      app    => $app->to_app,
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
      };

done_testing;
