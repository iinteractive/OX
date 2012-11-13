package OX::Meta::Role::HasMiddleware;
use Moose::Role;
use namespace::autoclean;

use List::MoreUtils 'any';
use Moose::Util::TypeConstraints 'find_type_constraint';

has middleware => (
    traits  => ['Array'],
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    handles => {
        middleware      => 'elements',
        _add_middleware => 'push',
    },
);

sub add_middleware {
    my $self = shift;
    my $opts = @_ > 1 ? { @_ } : $_[0];

    my $tc = find_type_constraint('OX::Types::Middleware');
    $tc->assert_valid($opts->{middleware});

    $self->_add_middleware($opts);
}

sub has_middleware_dependencies {
    my $self = shift;

    return any { %{ $_->{deps} } } $self->middleware;
}

sub all_middleware {
    my $self = shift;
    return $self->middleware;
}

=for Pod::Coverage
  add_middleware
  has_middleware_dependencies

=cut

1;
