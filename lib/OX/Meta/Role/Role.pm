package OX::Meta::Role::Role;
use Moose::Role;
use namespace::autoclean;

with 'OX::Meta::Role::HasRouteBuilders',
     'OX::Meta::Role::HasRoutes',
     'OX::Meta::Role::HasMiddleware';

no Moose::Role;

1;
