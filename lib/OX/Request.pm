package OX::Request;
use Moose;
use namespace::autoclean;
# ABSTRACT: request object for OX

extends 'Web::Request';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub default_encoding { 'UTF-8' }

sub _router { (shift)->env->{'ox.router'} }

=method mapping

=cut

sub mapping {
    my $self = shift;
    my $match = $self->env->{'plack.router.match'};
    return unless $match;
    return %{ $match->mapping };
}

=method uri_for

=cut

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

=pod

=for Pod::Coverage
  default_encoding

=cut

1;
