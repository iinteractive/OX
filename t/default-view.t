#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

BEGIN {
    package DefaultView::Meta::Method;
    use Moose::Role;

    around wrap => sub {
        my $orig = shift;
        my $self = shift;
        my ($body, %args) = @_;

        my $new_body = sub {
            my $self = shift;
            $self->$body(@_);
            return $self->render("$args{name}.tmpl");
        };

        return $self->$orig($new_body, %args);
    };

    $INC{'DefaultView/Meta/Method.pm'} = __FILE__;
}

BEGIN {
    package DefaultView;
    use Moose::Exporter;

    use Moose::Util 'with_traits';

    Moose::Exporter->setup_import_methods(with_meta => ['route']);

    sub route {
        my $meta = shift;
        my ($name, $code) = @_;
        my $method_meta = with_traits($meta->method_metaclass, 'DefaultView::Meta::Method');
        $meta->add_method($name => $method_meta->wrap(
            $code,
            name                 => $name,
            package_name         => $meta->name,
            associated_metaclass => $meta,
        ));
    }

    $INC{'DefaultView.pm'} = __FILE__;
}

{
    package MyApp::View;
    use Moose;

    sub render {
        my $self = shift;
        my ($file) = @_;

        return "this is the contents of $file";
    }
}

{
    package MyApp::Controller;
    use Moose;
    use DefaultView;

    has view => (
        is       => 'ro',
        isa      => 'MyApp::View',
        required => 1,
        handles  => ['render'],
    );

    route foo => sub { };
}

{
    package MyApp;
    use OX;

    has view => (
        is  => 'ro',
        isa => 'MyApp::View',
    );

    has controller => (
        is    => 'ro',
        isa   => 'MyApp::Controller',
        infer => 1,
    );

    router as {
        route '/' => 'controller.foo';
    };
}

test_psgi
    app    => MyApp->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET '/');
            ok($res->is_success);
            is($res->content, "this is the contents of foo.tmpl");
        }
    };

done_testing;
