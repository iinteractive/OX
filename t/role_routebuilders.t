#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Plack::Test;

use HTTP::Request::Common;

{
    package My::Custom::RouteBuilder;
    use Moose;
    with 'OX::RouteBuilder';

    sub compile_routes {
        my $self = shift;

        my ($defaults, $validations) = $self->extract_defaults_and_validations($self->params);

        return {
            path        => $self->path,
            defaults    => $defaults,
            target      => $self->route_spec,
            validations => $validations,
        };
    }

    sub parse_action_spec {
        my $class = shift;
        my ($action_spec) = @_;

        return unless $action_spec =~ s/^custom://;
        return sub { $action_spec };
    }
}

{
    package My::Custom::RouteBuilder2;
    use Moose;
    with 'OX::RouteBuilder';

    sub compile_routes {
        my $self = shift;

        my ($defaults, $validations) = $self->extract_defaults_and_validations($self->params);

        return {
            path        => $self->path,
            defaults    => $defaults,
            target      => $self->route_spec,
            validations => $validations,
        };
    }

    sub parse_action_spec {
        my $class = shift;
        my ($action_spec) = @_;

        return unless $action_spec =~ s/^custom2://;
        return sub { $action_spec };
    }
}

{
    package MyApp::Role;
    use OX::Role;

    router ['My::Custom::RouteBuilder'], as {
        route '/role' => 'custom:foo';
        ::like(
            ::exception { route '/role-error' => 'custom2:bar' },
            qr/Unknown action spec custom2:bar/,
        );
    };
}

{
    package MyApp;
    use OX;

    with 'MyApp::Role';

    router ['My::Custom::RouteBuilder2'], as {
        route '/class' => 'custom2:baz';
        ::like(
            ::exception { route '/class-error' => 'custom:quux' },
            qr/Unknown action spec custom:quux/,
        );
    };
}

test_psgi
    app => MyApp->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/role');
            ok($res->is_success);
            is($res->content, 'foo');
        }

        {
            my $res = $cb->(GET '/role-error');
            ok(!$res->is_success);
        }

        {
            my $res = $cb->(GET '/class');
            ok($res->is_success);
            is($res->content, 'baz');
        }

        {
            my $res = $cb->(GET '/class-error');
            ok(!$res->is_success);
        }
    };

done_testing;
