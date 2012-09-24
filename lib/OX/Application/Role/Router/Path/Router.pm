package OX::Application::Role::Router::Path::Router;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: implementation of OX::Application::Role::Router which uses Path::Router

use Plack::App::Path::Router::Custom 0.05;

with 'OX::Application::Role::Router', 'OX::Application::Role::Request';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub router_class { 'Path::Router' }

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

=pod

=for Pod::Coverage
  router_class
  app_from_router

=cut

1;
