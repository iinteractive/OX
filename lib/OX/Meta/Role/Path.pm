package OX::Meta::Role::Path;
use Moose::Role;

use OX::Util;

has path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub canonical_path {
    my $self = shift;

    return OX::Util::canonicalize_path($self->path);
}

no Moose::Role;

1;
