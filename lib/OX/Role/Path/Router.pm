package OX::Role::Path::Router;
use Moose::Role;
use namespace::autoclean;

use Plack::App::Path::Router::PSGI;

sub router_class { 'OX::Router::Path::Router' }

sub app_from_router {
    my $self = shift;
    my ($router) = @_;

    return Plack::App::Path::Router::PSGI->new(
        router => $router,
    )->to_app;
}

1;
