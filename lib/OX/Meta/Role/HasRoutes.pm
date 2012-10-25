package OX::Meta::Role::HasRoutes;
use Moose::Role;
use namespace::autoclean;

use Class::Load 'load_class';
use List::MoreUtils 'any';

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

sub add_route {
    my $self = shift;
    my $opts = @_ > 1 ? { @_ } : $_[0];

    confess("A route already exists for $opts->{path}")
        if $self->has_route_for($opts->{path});

    for my $mount ($self->mounts) {
        (my $prefix = $mount->{path}) =~ s{/$}{};
        if ($opts->{path} =~ m{^$prefix/}) {
            warn "The application mounted at $mount->{path} will shadow the "
               . "route declared at $opts->{path}";
        }
    }

    $self->_add_route($opts);
}

sub has_route_for {
    my $self = shift;
    my ($path) = @_;

    return any { $_->{path} eq $path } $self->routes;
}

sub add_mount {
    my $self = shift;
    my $opts = @_ > 1 ? { @_ } : $_[0];

    if (exists $opts->{class}) {
        load_class($opts->{class});
        confess "Class $opts->{class} must implement a to_app method"
            unless $opts->{class}->can('to_app');
    }

    (my $prefix = $opts->{path}) =~ s{/$}{};
    for my $route ($self->routes) {
        if ($route->{path} =~ m{^$prefix/}) {
            warn "The application mounted at $opts->{path} will shadow the "
               . "route declared at $route->{path}";
        }
    }

    $self->_add_mount($opts);
}

sub has_mount_for {
    my $self = shift;
    my ($path) = @_;

    return any { $_->{path} eq $path } $self->mounts;
}

no Moose::Role;

=for Pod::Coverage
  add_route
  has_route_for
  add_mount
  has_mount_for

=cut

1;
