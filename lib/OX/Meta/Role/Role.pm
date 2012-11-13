package OX::Meta::Role::Role;
use Moose::Role;
use namespace::autoclean;

with 'OX::Meta::Role::HasRouteBuilders',
     'OX::Meta::Role::HasRoutes',
     'OX::Meta::Role::HasMiddleware';

sub composition_class_roles {
    return 'OX::Meta::Role::Composite';
}

1;
