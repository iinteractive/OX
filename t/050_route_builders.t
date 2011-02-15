#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package RouteBuilder::REST;
    use Moose;

    with 'OX::RouteBuilder';

    sub compile_routes {
        my $self = shift;

        my $spec = $self->route_spec;
        my $params = $self->params;

        my ($defaults, $validations) = $self->extract_defaults_and_validations($params);
        $defaults = { %$spec, %$defaults };

        my $s = $self->service;

        return [
            $self->path,
            defaults    => $defaults,
            target      => sub {
                my ($req) = @_;

                my %match = %{ $req->env->{'plack.router.match'}->mapping };
                my $a = $match{action};
                my $component = $s->get_dependency($a)->get;
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

            },
            validations => $validations,
        ];
    }
}

{
    package OX::REST;
    sub import {
        my $meta = Class::MOP::class_of(caller);
        $meta->add_route_builder(
            class      => 'RouteBuilder::REST',
            route_spec => sub { ref($_[0]) ? () : { action => $_[0] } },
        );
    }
}
BEGIN { $INC{'OX/REST.pm'} = 1 }

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
    use OX::REST;

    component Root => 'Root';

    router as {
        route '/' => 'root';
    }, (root => depends_on('Component/Root'));
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

done_testing;
