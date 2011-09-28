package OX::Request;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

use OX::Response;

extends 'Plack::Request';

sub BUILDARGS {
    return {};
}

sub router { (shift)->env->{'ox.router'} }

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
    return $uri_base . $self->router->uri_for( %$route );
}

sub new_response {
    my $self = shift;
    OX::Response->new( @_ );
}

__PACKAGE__->meta->make_immutable;

1;
