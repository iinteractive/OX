package OX::Meta::Role::Path;
use Moose::Role;
use namespace::autoclean;

use OX::Util;

requires 'type';

has path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has definition_location => (
    is      => 'ro',
    isa     => 'Str',
    default => '(unknown)',
);

sub canonical_path {
    my $self = shift;

    return OX::Util::canonicalize_path($self->path);
}

=for Pod::Coverage
  canonical_path

=cut

1;
