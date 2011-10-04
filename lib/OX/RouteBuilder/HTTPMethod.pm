package OX::RouteBuilder::HTTPMethod;
use Moose;
use namespace::autoclean;

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
    my $class = shift;
    my ($action_spec) = @_;

    return if ref($action_spec);
    return unless $action_spec =~ /^(\w+)$/;

    return {
        action => $1,
    };
}

__PACKAGE__->meta->make_immutable;

1;
