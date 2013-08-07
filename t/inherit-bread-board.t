#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Container;
    use Moose;
    use Bread::Board::Declare;
}
{
    package App;
    use OX;
    extends 'Container';
}

new_ok('App');

done_testing;
