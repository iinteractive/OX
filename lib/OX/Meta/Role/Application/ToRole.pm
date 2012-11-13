package OX::Meta::Role::Application::ToRole;
use Moose::Role;

use Moose::Util 'does_role';

with 'OX::Meta::Role::Application';

sub _apply_routes {
    my $self = shift;
    my ($role1, $role2) = @_;

    if (!does_role($role2, 'OX::Meta::Role::Role')) {
        confess("OX::Roles can only be applied to other OX::Roles");
    }

    for my $route ($role1->routes) {
        $role2->_add_route($route)
            unless $role2->has_route_for($route->path);
    }

    for my $mount ($role1->mounts) {
        $role2->_add_mount($mount)
            unless $role2->has_mount_for($mount->{path});
    }
}

no Moose::Role;

1;
