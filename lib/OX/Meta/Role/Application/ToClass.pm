package OX::Meta::Role::Application::ToClass;
use Moose::Role;
use namespace::autoclean;

use Moose::Util 'does_role';

with 'OX::Meta::Role::Application';

sub _apply_routes {
    my $self = shift;
    my ($role, $class) = @_;

    if (!does_role($class, 'OX::Meta::Role::Class')) {
        confess("OX::Roles can only be applied to OX classes");
    }

    for my $route ($role->routes) {
        $class->_add_route($route)
            unless $class->has_route_for($route->{path});
    }
}

no Moose::Role;

1;
