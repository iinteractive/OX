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

has middleware => (
    traits => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_middleware => 'push',
        middleware     => 'elements',
    },
);

sub has_router_config {
    my $self = shift;
    return any { $_->has_local_router_config }
           grep { Moose::Util::does_role($_, __PACKAGE__) }
           map { $_->meta }
           $self->linearized_isa;
}

sub full_router_config {
    my $self = shift;

    my @router_configs = map { $_->router_config->clone }
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

before add_middleware => sub {
    my $self = shift;
    my ($middleware) = @_;
    Class::MOP::load_class($middleware)
        unless ref($middleware);
};

no Moose::Role;

1;
