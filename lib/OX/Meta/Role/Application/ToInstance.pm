package OX::Meta::Role::Application::ToInstance;
use Moose::Role;
use namespace::autoclean;

with 'OX::Meta::Role::Application';

sub _apply_routes {
    my $self = shift;
    my ($role, $obj) = @_;

    $obj->regenerate_router_config;
}

1;
