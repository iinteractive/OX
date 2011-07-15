package OX::Meta::Role::Class;
use Moose::Role;
use namespace::autoclean;

use List::MoreUtils qw(any);

has router => (
    is        => 'rw',
    does      => 'Bread::Board::Service',
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
    does      => 'Bread::Board::Service',
    predicate => 'has_local_router_config',
);

has controller_dependencies => (
    is        => 'rw',
    does      => 'Bread::Board::Service',
    predicate => 'has_local_controller_dependencies',
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
    isa     => 'ArrayRef[Bread::Board::Service]',
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

    my %routes = map { %{ $_->value } } @router_configs;
    return Bread::Board::Literal->new(
        name  => 'config',
        value => \%routes,
    );
}

sub has_controller_dependencies {
    my $self = shift;
    return any { $_->has_local_controller_dependencies }
           grep { Moose::Util::does_role($_, __PACKAGE__) }
           map { $_->meta }
           $self->linearized_isa;
}

sub full_controller_dependencies {
    my $self = shift;

    my @controller_deps = map { $_->controller_dependencies->clone }
                          grep { $_->has_local_controller_dependencies }
                          grep { Moose::Util::does_role($_, __PACKAGE__) }
                          map { $_->meta }
                          $self->linearized_isa;
    my $deps = { map { %{ $_->value } } @controller_deps };

    return Bread::Board::Literal->new(
        name  => 'dependencies',
        value => $deps,
    );
}

before add_middleware => sub {
    my $self = shift;
    my ($middleware) = @_;
    Class::MOP::load_class($middleware->class)
        if $middleware->does('Bread::Board::Service::WithClass');
};

1;
