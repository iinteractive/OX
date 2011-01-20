package OX::Meta::Role::Class;
use Moose::Role;

has routes => (
    traits  => ['Hash'],
    isa     => 'HashRef[HashRef]',
    default => sub { {} },
    handles => {
        has_routes    => 'count',
        paths         => 'keys',
        add_route     => 'set',
        router_config => 'elements',
    },
);

has resources => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Bread::Board::Service]',
    default => sub { [] },
    handles => {
        has_resources => 'count',
        resources     => 'elements',
        add_resource  => 'push',
    },
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

no Moose::Role;

1;
