package OX::Meta::Role::Class;
use Moose::Role;
use namespace::autoclean;

use Class::Load 'load_class';
use List::MoreUtils 'any';
use Moose::Util 'does_role', 'find_meta';
use Moose::Util::TypeConstraints 'find_type_constraint';

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

has routes => (
    traits  => ['Array'],
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    handles => {
        routes     => 'elements',
        _add_route => 'push',
    },
);

has mounts => (
    traits  => ['Array'],
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    handles => {
        mounts     => 'elements',
        has_mounts => 'count',
        _add_mount => 'push',
    },
);

has middleware => (
    traits  => ['Array'],
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    handles => {
        middleware      => 'elements',
        _add_middleware => 'push',
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

sub add_route {
    my $self = shift;
    my $opts = @_ > 1 ? { @_ } : $_[0];

    confess("A route already exists for $opts->{path}")
        if $self->has_route_for($opts->{path});

    $self->_add_route($opts);
}

sub has_route_for {
    my $self = shift;
    my ($path) = @_;

    return any { $_->{path} eq $path } $self->routes;
}

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

    return { map { $_->{path} => $_ } $self->routes };
}

sub add_mount {
    my $self = shift;
    my $opts = @_ > 1 ? { @_ } : $_[0];

    if (exists $opts->{class}) {
        load_class($opts->{class});
        confess "Class $opts->{class} must implement a to_app method"
            unless $opts->{class}->can('to_app');
    }

    $self->_add_mount($opts);
}

sub has_mount_for {
    my $self = shift;
    my ($path) = @_;

    return any { $_->{path} eq $path } $self->mounts;
}

sub add_middleware {
    my $self = shift;
    my $opts = @_ > 1 ? { @_ } : $_[0];

    my $tc = find_type_constraint('OX::Types::Middleware');
    $tc->assert_valid($opts->{middleware});

    $self->_add_middleware($opts);
}

sub has_middleware_dependencies {
    my $self = shift;

    return any { %{ $_->{deps} } } $self->middleware;
}

=pod

=for Pod::Coverage
  add_middleware
  add_mount
  add_route
  add_route_builder
  has_middleware_dependencies
  has_mount_for
  has_route_for
  route_builder_for
  router_config

=cut

1;
