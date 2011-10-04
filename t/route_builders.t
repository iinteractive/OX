#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;
use Test::Fatal;

{
    package RouteBuilder::REST;
    use Moose;

    use Moose::Util::TypeConstraints qw(find_type_constraint);

    with 'OX::RouteBuilder';

    sub compile_routes {
        my $self = shift;
        my ($app) = @_;

        my $spec = $self->route_spec;
        my $params = $self->params;

        my ($defaults, $validations) = $self->extract_defaults_and_validations($params);
        $defaults = { %$spec, %$defaults };

        my $target = sub {
            my ($req) = @_;

            my %match = $req->mapping;
            my $a = $match{action};

            my $s = $app->fetch($a);
            return [
                500,
                [],
                [blessed($app) . " has no service $a"]
            ] unless $s;

            my $component = $s->get;

            my $method = lc($req->method);

            if ($component->can($method)) {
                return $component->$method(@_);
            }
            elsif ($component->can('any')) {
                return $component->any(@_);
            }
            else {
                return [
                    500,
                    [],
                    ["Component $component has no method $method"]
                ];
            }

        };

        return {
            path        => $self->path,
            defaults    => $defaults,
            target      => $target,
            validations => $validations,
        };
    }

    sub parse_action_spec {
        my $self = shift;
        my ($action_spec) = @_;
        return if ref($action_spec);
        return unless $action_spec =~ /^REST:(.*)$/;
        return {
            action => $1,
        }
    }
}

{
    package Root;
    use Moose;

    sub get { "root: get" }
    sub any {
        my $self = shift;
        my ($req) = @_;
        return "root default: " . $req->method;
    }
}

{
    package Foo;
    use OX;

    has root => (
        is  => 'ro',
        isa => 'Root',
    );

    router ['RouteBuilder::REST'], as {
        route '/' => 'REST:root';
    }, (root => 'root');
}

test_psgi
    app => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, "root: get", "right content for GET");
        }
        {
            my $req = HTTP::Request->new(POST => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, "root default: POST", "right content for POST");
        }
    };

{
    package Bar;
    use OX;

    ::like(
        ::exception {
            router ['RouteBuilder::REST'], as {
                route '/' => sub { };
            }
        },
        qr/^Unknown action spec /,
        "default routes don't exist when routebuilders are specified"
    );
}

done_testing;
