package OX::RouteBuilder::ControllerAction;
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
        my $c = $match{controller};
        my $a = $match{action};

        my $s = $app->fetch($c);
        return [
            500,
            [],
            [blessed($app) . " has no service $c"]
        ] unless $s;

        my $component = $s->get;

        return $component->$a(@_)
            if $component;

        return [
            500,
            [],
            ["Component $component has no action $a"]
        ];
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

    return if ref($action_spec) || $action_spec !~ /^[^\.]+\.[^\.]+$/;

    my ($controller, $action) = split /\./, $action_spec;
    return {
        controller => $controller,
        action     => $action,
    };
}

__PACKAGE__->meta->make_immutable;

1;
