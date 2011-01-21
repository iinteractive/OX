package OX::Meta::Role::Class;
use Moose::Role;

has router => (
    is        => 'rw',
    isa       => 'Bread::Board::Service',
    predicate => 'has_router',
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
