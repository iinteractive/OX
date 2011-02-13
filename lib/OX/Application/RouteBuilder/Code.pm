package OX::Application::RouteBuilder::Code;
use Moose;

with 'OX::Application::RouteBuilder';

sub compile_routes {
    my $self = shift;

    return [
        $self->path,
        target => $self->route_spec,
    ];
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
