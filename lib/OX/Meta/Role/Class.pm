package OX::Meta::Role::Class;
use Moose::Role;

has router => (
    is        => 'rw',
    isa       => 'Path::Router',
    predicate => 'has_router',
);

has router_config => (
    is        => 'rw',
    isa       => 'Bread::Board::Service',
    predicate => 'has_router_config',
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

no Moose::Role;

1;
