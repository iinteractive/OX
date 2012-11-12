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

    my $config = {
        map {
            my $config = $_;
            map { OX::Util::canonicalize_path($_) => [ $_, $config->{$_} ] }
                keys %$config
        }
        map { $_->_local_router_config }
        grep { $_ && does_role($_, 'OX::Meta::Role::Class') }
        map { find_meta($_) }
        reverse $self->linearized_isa
    };

    return { map { @$_ } values %$config };
}

sub _local_router_config {
    my $self = shift;

    return { map { $_->path => $_->router_config } $self->routes };
}

=pod

=for Pod::Coverage
  router_config

=cut

1;
