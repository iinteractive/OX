use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorTests;

name 'OX';
all_from 'lib/OX.pm';
auto_set_repository;

license 'perl';

# prereqs
requires 'MooseX::NonMoose'               => '0';
requires 'Bread::Board::Declare'          => '0';
requires 'Plack::App::Path::Router::PSGI' => '0';

# things the tests need
build_requires 'Test::More'      => '0.62';
build_requires 'Test::Exception' => '0.21';

tests('t/*.t');
author_tests('t/author/*.t');

auto_install;
WriteAll();

