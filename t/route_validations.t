#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{
    package Blog::Controller;
    use Moose;

    sub blog { "index" }

    sub blog_by_id {
        my $self = shift;
        my ($r, $id) = @_;
        return "blog post number $id";
    }

    sub blog_by_date {
        my $self = shift;
        my ($r, $y, $m, $d) = @_;
        return "blog post on $y-$m-$d";
    }

    sub blog_by_search {
        my $self = shift;
        my ($r, $search) = @_;
        return "search for $search";
    }
}

{
    package Blog;
    use OX;

    has root => (
        is  => 'ro',
        isa => 'Blog::Controller',
    );

    router as {
        route '/blog' => 'root.blog';
        route '/blog/:id' => 'root.blog_by_id', (
            id => { isa => 'Int' },
        );
        route '/blog/:search' => 'root.blog_by_search', (
            search => { isa => qr/^\D+$/ },
        );
        route '/blog/:year/:month/:day' => 'root.blog_by_date', (
            year  => { isa => 'Int' },
            month => { isa => 'Int' },
            day   => { isa => 'Int' },
        );
    };
}

test_psgi
    app => Blog->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/blog');
            ok($res->is_success) || diag($res->content);
            is($res->content, 'index');
        }
        {
            my $res = $cb->(GET '/blog/2');
            ok($res->is_success) || diag($res->content);
            is($res->content, 'blog post number 2');
        }
        {
            my $res = $cb->(GET '/blog/foo');
            ok($res->is_success) || diag($res->content);
            is($res->content, 'search for foo');
        }
        {
            my $res = $cb->(GET '/blog/foo123');
            is($res->code, 404);
        }
        {
            my $res = $cb->(GET '/blog/2012/10/7');
            ok($res->is_success) || diag($res->content);
            is($res->content, 'blog post on 2012-10-7');
        }
        {
            my $res = $cb->(GET '/blog/foo/bar/baz');
            is($res->code, 404);
        }
    };

done_testing;
