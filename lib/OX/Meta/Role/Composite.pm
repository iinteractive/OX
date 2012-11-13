package OX::Meta::Role::Composite;
use Moose::Role;
use namespace::autoclean;

use Moose::Util 'does_role';

with 'OX::Meta::Role::Role';

around apply_params => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self = Moose::Util::MetaRole::apply_metaroles(
        for => $self,
        role_metaroles => {
            application_to_class    => ['OX::Meta::Role::Application::ToClass'],
            application_to_role     => ['OX::Meta::Role::Application::ToRole'],
            application_to_instance => ['OX::Meta::Role::Application::ToInstance'],
        },
    );

    $self->_merge_routes;

    return $self;
};

sub _merge_routes {
    my $self = shift;

    my %routes;
    my %mounts;
    for my $role (@{ $self->get_roles }) {
        next unless does_role($role, 'OX::Meta::Role::Role');
        for my $route ($role->routes) {
            my $canonical = $route->canonical_path;
            if (exists $routes{$canonical}) {
                $routes{$canonical} = OX::Meta::Conflict->new(
                    path      => $canonical,
                    conflicts => [$routes{$canonical}, $route],
                );
            }
            else {
                $routes{$canonical} = $route;
            }
        }
        for my $mount ($role->mounts) {
            my $path = $mount->path;
            if (exists $mounts{$path}) {
                $mounts{$path} = OX::Meta::Conflict->new(
                    path      => $path,
                    conflicts => [$mounts{$path}, $mount],
                );
            }
            else {
                $mounts{$path} = $mount;
            }
        }
    }

    for my $route (values %routes) {
        $self->_add_route($route);
    }

    for my $mount (values %mounts) {
        $self->_add_mount($mount);
    }
}

no Moose::Role;

1;
