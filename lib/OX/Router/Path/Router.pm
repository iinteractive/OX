package OX::Router::Path::Router;
use Moose;
use namespace::autoclean;

use Class::Load 'load_class';
use OX::Router::Path::Router::Route;

extends 'Path::Router';

has '+route_class' => (default => 'OX::Router::Path::Router::Route');

has request_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    handles  => {
        new_request => 'new',
    },
);

sub BUILD {
    my $self = shift;
    load_class($self->request_class);
}

sub add_compiled_route {
    my $self = shift;
    my ($compiled) = @_;
    my $path = delete $compiled->{path};
    $self->add_route($path => %$compiled);
}

__PACKAGE__->meta->make_immutable;

1;
