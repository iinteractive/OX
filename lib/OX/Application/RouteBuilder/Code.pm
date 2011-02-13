package OX::Application::RouteBuilder::Code;
use Moose;

with 'OX::Application::RouteBuilder';

sub compile_routes {
    my $self = shift;

    my ($defaults, $validations) = $self->extract_defaults_and_validations($self->params);

    return [
        $self->path,
        defaults    => $defaults,
        target      => $self->route_spec,
        validations => $validations,
    ];
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
