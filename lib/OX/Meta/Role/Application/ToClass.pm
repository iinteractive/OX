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

    for my $conflict ($role->mixed_conflicts) {
        confess($conflict->message);
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

    for my $mount ($role->mounts) {
        if (!$class->has_mount_for($mount->path)) {
            if ($mount->isa('OX::Meta::Conflict')) {
                confess($mount->message);
            }
            else {
                $class->_add_mount($mount);
            }
        }
    }
}

=for Pod::Coverage

=cut

1;
