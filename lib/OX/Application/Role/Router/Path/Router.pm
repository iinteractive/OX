package OX::Application::Role::Router::Path::Router;
use Moose::Role;
use namespace::autoclean;

use Plack::App::Path::Router::PSGI;

with 'OX::Application::Role::Router';

sub router_class;
has router_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'OX::Router::Path::Router',
);

sub app_from_router {
    my $self = shift;
    my ($router) = @_;

    return Plack::App::Path::Router::PSGI->new(
        router => $router,
    )->to_app;
}

1;
