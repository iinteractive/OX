#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Custom::App;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Component';

    has thing => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    sub call {
        my $self = shift;
        my ($env) = @_;

        return [200, [], ["$env->{PATH_INFO}: " . $self->thing]];
    }
}

{
    package OX::App;
    use OX;

    has thing => (
        is    => 'ro',
        isa   => 'Str',
        value => 'THING',
    );

    router as {
        mount '/' => 'Custom::App' => (
            thing => 'thing',
        );
    };
}

test_psgi
    app    => OX::App->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, "/foo: THING", "got the right content");
        }
    };

done_testing;
