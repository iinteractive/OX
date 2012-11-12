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
        if (!$class->has_route_for($route->path)) {
            if ($route->isa('OX::Meta::Conflict')) {
                confess($route->message);
            }
            else {
                $class->_add_route($route);
            }
        }
    }
}

no Moose::Role;

1;
