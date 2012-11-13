package OX::Meta::Role::HasRoutes;
use Moose::Role;
use namespace::autoclean;

use Class::Load 'load_class';
use List::MoreUtils 'any';

use OX::Meta::Conflict;
use OX::Meta::Mount::App;
use OX::Meta::Mount::Class;
use OX::Meta::Route;
use OX::Util;

has routes => (
    traits  => ['Array'],
    isa     => 'ArrayRef[OX::Meta::Route|OX::Meta::Conflict]',
    default => sub { [] },
    handles => {
        routes     => 'elements',
        _add_route => 'push',
    },
);

has mounts => (
    traits  => ['Array'],
    isa     => 'ArrayRef[OX::Meta::Mount|OX::Meta::Conflict]',
    default => sub { [] },
    handles => {
        mounts     => 'elements',
        has_mounts => 'count',
        _add_mount => 'push',
    },
);

has mixed_conflicts => (
    traits  => ['Array'],
    isa     => 'ArrayRef[OX::Meta::Conflict]',
    default => sub { [] },
    handles => {
        mixed_conflicts     => 'elements',
        _add_mixed_conflict => 'push',
    },
);

sub add_route {
    my $self = shift;

    my $route = OX::Meta::Route->new(@_)
        unless @_ == 1 && blessed($_[0]);

    my $path = $route->path;

    confess("A route already exists for $path")
        if $self->has_route_for($path);

    for my $mount ($self->mounts) {
        my $mount_path = $mount->path;
        (my $prefix = $mount_path) =~ s{/$}{};
        if ($path =~ m{^$prefix/}) {
            warn "The application mounted at $mount_path will shadow the "
               . "route declared at $path";
        }
    }

    $self->_add_route($route);
}

sub has_route_for {
    my $self = shift;
    my ($path) = @_;

    my $canonical = OX::Util::canonicalize_path($path);

    return any { $_->canonical_path eq $canonical } $self->routes;
}

sub add_mount {
    my $self = shift;
    my $opts = @_ > 1 ? { @_ } : $_[0];

    my $mount;
    if (exists $opts->{class}) {
        load_class($opts->{class});
        confess "Class $opts->{class} must implement a to_app method"
            unless $opts->{class}->can('to_app');
        $mount = OX::Meta::Mount::Class->new($opts);
    }
    else {
        $mount = OX::Meta::Mount::App->new($opts);
    }

    my $path = $mount->path;

    (my $prefix = $path) =~ s{/$}{};
    for my $route ($self->routes) {
        my $route_path = $route->path;
        if ($route_path =~ m{^$prefix/}) {
            warn "The application mounted at $path will shadow the "
               . "route declared at $route_path";
        }
    }

    $self->_add_mount($mount);
}

sub has_mount_for {
    my $self = shift;
    my ($path) = @_;

    return any { $_->path eq $path } $self->mounts;
}

=for Pod::Coverage
  add_route
  has_route_for
  add_mount
  has_mount_for

=cut

1;
