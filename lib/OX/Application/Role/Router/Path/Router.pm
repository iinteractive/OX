package OX::Application::Role::Router::Path::Router;
use Moose::Role;
use namespace::autoclean;

use Plack::App::Path::Router::Custom 0.05;

with 'OX::Application::Role::Router';

sub router_class;
has router_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Path::Router',
);

sub app_from_router {
    my $self = shift;
    my ($router) = @_;

    return Plack::App::Path::Router::Custom->new(
        router => $router,
        new_request => sub {
            $self->new_request(@_);
        },
        target_to_app => sub {
            my ($target) = @_;
            blessed($target) && $target->can('to_app')
                ? $target->to_app
                : $target;
        },
        handle_response => sub {
            $self->handle_response(@_);
        },
    )->to_app;
}

1;
