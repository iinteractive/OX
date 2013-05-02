#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

{

    package Foo;
    use OX;

}

my $app = Foo->new;
weaken $app;
ok(!$app, "app without references is released");

done_testing;
