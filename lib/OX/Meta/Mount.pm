package OX::Meta::Mount;
use Moose;

with 'OX::Meta::Role::Path';

sub type { 'mount' }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
