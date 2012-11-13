package OX::Meta::Route;
use Moose;

with 'OX::Meta::Role::Path';

has class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has route_spec => (
    is       => 'ro',
    required => 1,
);

has params => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub router_config {
    my $self = shift;

    return {
        path       => $self->path,
        class      => $self->class,
        route_spec => $self->route_spec,
        params     => $self->params,
    };
}

sub type { 'route' }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
