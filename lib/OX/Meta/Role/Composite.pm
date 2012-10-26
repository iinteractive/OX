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

    # XXX conflict detection
    for my $role (@{ $self->get_roles }) {
        if (does_role($role, 'OX::Meta::Role::Role')) {
            for my $route ($role->routes) {
                $self->_add_route($route)
                    unless $self->has_route_for($route->{path});
            }
        }
    }
}

no Moose::Role;

1;
