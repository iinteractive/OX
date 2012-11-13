package OX::Meta::Conflict;
use Moose;

with 'OX::Meta::Role::Path';

has conflicts => (
    traits  => ['Array'],
    isa     => 'ArrayRef[OX::Meta::Role::Path]',
    default => sub { [] },
    handles => {
        conflicts    => 'elements',
        add_conflict => 'push',
    },
);

sub message {
    my $self = shift;

    my @descs = map {
        $_->type . " " . $_->path . " (" . $_->definition_location . ")"
    } $self->conflicts;

    return "Conflicting paths found: " . join(', ', @descs);
}

sub type { 'conflict' }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
