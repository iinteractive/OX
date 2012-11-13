package OX::Meta::Role::HasRouteBuilders;
use Moose::Role;
use namespace::autoclean;

use Class::Load 'load_class';

use OX::RouteBuilder;

has route_builders => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        route_builders     => 'elements',
        has_route_builders => 'count',
        _add_route_builder => 'push',
    },
);

sub add_route_builder {
    my $self = shift;
    my ($route_builder) = @_;
    load_class($route_builder);
    $self->_add_route_builder($route_builder);
}

sub route_builder_for {
    my $self = shift;
    my ($action_spec) = @_;

    my @route_specs = grep { defined $_->[1] }
                      map { [ $_, $_->parse_action_spec($action_spec) ] }
                      $self->route_builders;
    if (@route_specs < 1) {
        die "Unknown action spec $action_spec";
    }
    elsif (@route_specs > 1) {
        die "Ambiguous action spec $action_spec (matched by "
          . join(', ', map { $_->[0] } @route_specs)
          . ")";
    }
    else {
        return @{ $route_specs[0] };
    }
}

=for Pod::Coverage
  add_route_builder
  route_builder_for

=cut

1;
