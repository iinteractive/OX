package OX::Role::Path::Router;
use Moose::Role;

use Plack::App::Path::Router::PSGI;

sub router_class { 'OX::Router' }

sub app_from_router {
    my $self = shift;
    my ($router) = @_;

    return Plack::App::Path::Router::PSGI->new(
        router => $router,
    )->to_app;
}

no Moose::Role;

1;
