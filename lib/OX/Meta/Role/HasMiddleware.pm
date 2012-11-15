package OX::Meta::Role::HasMiddleware;
use Moose::Role;
use namespace::autoclean;

use List::MoreUtils 'any';

use OX::Meta::Middleware;

has middleware => (
    traits  => ['Array'],
    isa     => 'ArrayRef[OX::Meta::Middleware]',
    default => sub { [] },
    handles => {
        middleware        => 'elements',
        _add_middleware   => 'push',
        _clear_middleware => 'clear',
    },
);

sub add_middleware {
    my $self = shift;

    $self->_add_middleware(OX::Meta::Middleware->new(@_));
}

sub has_middleware_dependencies {
    my $self = shift;

    return any { %{ $_->dependencies } } $self->middleware;
}

sub all_middleware {
    my $self = shift;
    return $self->middleware;
}

=for Pod::Coverage
  add_middleware
  has_middleware_dependencies
  all_middleware

=cut

1;
