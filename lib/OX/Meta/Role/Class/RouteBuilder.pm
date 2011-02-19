package OX::Meta::Role::Class::RouteBuilder;
use Moose::Role;

has route_builders => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_route_builder => 'push',
        route_builders    => 'elements',
    },
);

before add_route_builder => sub {
    my $self = shift;
    my ($routebuilder) = @_;
    Class::MOP::load_class($routebuilder);
};

sub route_builder_for {
    my $self = shift;
    my ($action_spec) = @_;

    my @route_specs = grep { defined $_->[1] }
                      map { [ $_, $_->parse_action_spec($action_spec) ] }
                      $self->route_builders;
    if (@route_specs < 1) {
        die "Unknown route spec $action_spec";
    }
    elsif (@route_specs > 1) {
        die "Ambiguous route spec $action_spec (matched by "
          . join(', ', map { $_->[0] } @route_specs)
          . ")";
    }
    else {
        return @{ $route_specs[0] };
    }

}

no Moose::Role;

1;
