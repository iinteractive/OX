package OX::Router;
use Moose;

extends 'Path::Router';

use OX::Router::Route;

# XXX: ugh, what i really want to do here is:
# has '+route_class' => (default => 'OX::Router::Route');

sub add_route {
    my ($self, $path, %options) = @_;
    push @{$self->routes} => OX::Router::Route->new(
        path  => $path,
        %options
    );
    $self->clear_match_code;
}

sub insert_route {
    my ($self, $path, %options) = @_;
    my $at = delete $options{at} || 0;

    my $route = OX::Router::Route->new(
        path  => $path,
        %options
    );
    my $routes = $self->routes;

    if (! $at) {
        unshift @$routes, $route;
    } elsif ($#{$routes} < $at) {
        push @$routes, $route;
    } else {
        splice @$routes, $at, 0, $route;
    }
    $self->clear_match_code;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
