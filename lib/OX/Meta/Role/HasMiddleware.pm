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

has 'needs_reresolve' => (
    isa=>'Bool',
    is=>'ro',
    lazy_build=>1,
);
sub _build_needs_reresolve {
    my $self = shift;

    foreach ($self->middleware) {
        return 1 if $_->needs_reresolve;
    }
    return;
}

sub add_middleware {
    my ($self, %args) = @_;

    if ($args{dependencies}) {
        my $meta = $self->name->meta;
        my $needs_reresolve = 0;
        foreach my $dep (values %{$args{dependencies}} ) {
            next if blessed($dep) && $dep->isa('Bread::Board::Literal');
            my $attrib = $meta->get_attribute($dep);
            if (!$attrib->lifecycle || $attrib->lifecycle ne 'Singleton') {
                $needs_reresolve = 1;
                last;
            }
        }
        $args{needs_reresolve} = $needs_reresolve;
    }

    $self->_add_middleware(OX::Meta::Middleware->new( %args ));
}

sub all_middleware {
    my $self = shift;
    return $self->middleware;
}

=for Pod::Coverage
  add_middleware
  all_middleware

=cut

1;
