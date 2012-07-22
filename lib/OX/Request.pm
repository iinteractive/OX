package OX::Request;
use Moose;
use namespace::autoclean;

extends 'Web::Request';

sub default_encoding { 'UTF-8' }

sub _router { (shift)->env->{'ox.router'} }

sub mapping {
    my $self = shift;
    my $match = $self->env->{'plack.router.match'};
    return unless $match;
    return %{ $match->mapping };
}

sub uri_for {
    my ($self, $route) = @_;
    my $uri_base = $self->script_name || '/';
    $uri_base .= '/' unless $uri_base =~ m+/$+;
    my $path_info = $self->_router->uri_for( %$route );
    confess "No URI found for route"
        unless defined($path_info);
    return $uri_base . $path_info;
}

__PACKAGE__->meta->make_immutable;

1;
