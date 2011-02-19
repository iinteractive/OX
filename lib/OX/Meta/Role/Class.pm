package OX::Meta::Role::Class;
use Moose::Role;

use List::MoreUtils qw(any);

has router => (
    is        => 'rw',
    isa       => 'Path::Router',
    predicate => 'has_router',
);

has routes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[HashRef]',
    default => sub { {} },
    handles => {
        add_route => 'set',
    },
);

has router_config => (
    is        => 'rw',
    isa       => 'Bread::Board::Service',
    predicate => 'has_local_router_config',
);

has components => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Bread::Board::Service]',
    default => sub { [] },
    handles => {
        has_components => 'count',
        components     => 'elements',
        add_component  => 'push',
    },
);

has config => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Bread::Board::Service]',
    default => sub { [] },
    handles => {
        has_config => 'count',
        config     => 'elements',
        add_config => 'push',
    },
);

has mounts => (
    traits  => ['Hash'],
    isa     => 'HashRef[HashRef]',
    default => sub { {} },
    handles => {
        has_mounts  => 'count',
        mount_paths => 'keys',
        add_mount   => 'set',
        mount       => 'get',
    },
);

has route_builders => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_route_builder => 'push',
        route_builders    => 'elements',
    },
);

has middleware => (
    traits => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_middleware => 'push',
        middleware     => 'elements',
    },
);

sub has_any_config {
    my $self = shift;
    return any { $_->has_config }
           grep { Moose::Util::does_role($_, __PACKAGE__) }
           map { $_->meta }
           $self->linearized_isa;
}

sub get_all_config {
    my $self = shift;
    return map { $_->config }
           grep { Moose::Util::does_role($_, __PACKAGE__) }
           map { $_->meta }
           $self->linearized_isa;
}

sub has_any_components {
    my $self = shift;
    return any { $_->has_components }
           grep { Moose::Util::does_role($_, __PACKAGE__) }
           map { $_->meta }
           $self->linearized_isa;
}

sub get_all_components {
    my $self = shift;
    return map { $_->components }
           grep { Moose::Util::does_role($_, __PACKAGE__) }
           map { $_->meta }
           $self->linearized_isa;
}

sub has_router_config {
    my $self = shift;
    return any { $_->has_local_router_config }
           grep { Moose::Util::does_role($_, __PACKAGE__) }
           map { $_->meta }
           $self->linearized_isa;
}

sub full_router_config {
    my $self = shift;

    my @router_configs = map { $_->router_config }
                         grep { $_->has_local_router_config }
                         grep { Moose::Util::does_role($_, __PACKAGE__) }
                         map { $_->meta }
                         $self->linearized_isa;

    my %routes =       map { %{ $_->block->()    } } @router_configs;
    my %dependencies = map { %{ $_->dependencies } } @router_configs;
    return Bread::Board::BlockInjection->new(
        name         => 'config',
        block        => sub { \%routes },
        dependencies => \%dependencies,
    );
}

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

before add_middleware => sub {
    my $self = shift;
    my ($middleware) = @_;
    Class::MOP::load_class($middleware)
        unless ref($middleware);
};

no Moose::Role;

1;
