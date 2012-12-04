package OX::Meta::Role::Class;
use Moose::Role;
use namespace::autoclean;

use Moose::Util 'does_role', 'find_meta';

use OX::RouteBuilder;
use OX::Util;

with 'OX::Meta::Role::HasRouteBuilders',
     'OX::Meta::Role::HasRoutes',
     'OX::Meta::Role::HasMiddleware';

sub router_config {
    my $self = shift;

    return {
        map { %{ $_->_local_router_config } }
        grep { $_ && does_role($_, 'OX::Meta::Role::Class') }
        map { find_meta($_) }
        reverse $self->linearized_isa
    };
}

sub _local_router_config {
    my $self = shift;

    return { map { $_->path => $_->router_config } $self->routes };
}

sub all_middleware {
    my $self = shift;
    return map { $_->middleware }
           grep { $_ && does_role($_, 'OX::Meta::Role::Class') }
           map { find_meta($_) }
           $self->linearized_isa;
}

sub clear_app_state {
    my $self = shift;
    $self->_clear_routes;
    $self->_clear_mounts;
    $self->_clear_mixed_conflicts;
    $self->_clear_middleware;
    $self->_clear_route_builders;
}

=pod

=for Pod::Coverage
  router_config
  all_middleware
  clear_app_state

=cut

1;
