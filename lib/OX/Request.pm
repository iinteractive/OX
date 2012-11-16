package OX::Request;
use Moose;
use namespace::autoclean;
# ABSTRACT: request object for OX

extends 'Web::Request' => { -version => 0.05 };

=head1 SYNOPSIS

  use OX::Request;

  my $req = OX::Request->new(env => $env);

=head1 DESCRIPTION

This class is a simple subclass of L<Web::Request> which adds a couple more
features. It adds some methods to access various useful parts of the routing
process, and it also sets the C<default_encoding> to C<UTF-8>.

=cut

sub default_encoding { 'UTF-8' }
sub response_class   { 'OX::Response' }

sub _router { (shift)->env->{'ox.router'} }

=method mapping

This returns the C<mapping> of the current router match, if you are using
L<Path::Router> as the router.

=cut

sub mapping {
    my $self = shift;
    my $match = $self->env->{'plack.router.match'};
    return unless $match;
    return $match->mapping;
}

=method uri_for($route)

This calls C<uri_for> on the given route hashref, and returns the absolute URI
path that results (including prepending C<SCRIPT_NAME>). If a string is passed
rather than a hashref, this is treated as equivalent to
C<< { name => $route } >>.

=cut

sub uri_for {
    my ($self, $route) = @_;

    my $uri_base = $self->script_name || '/';
    $uri_base .= '/' unless $uri_base =~ m+/$+;

    if (!ref($route)) {
        $route = { name => $route };
    }

    my $path_info = $self->_router->uri_for( %$route );

    confess "No URI found for route"
        unless defined($path_info);

    return $uri_base . $path_info;
}

__PACKAGE__->meta->make_immutable;

=pod

=for Pod::Coverage
  default_encoding
  response_class

=cut

1;
