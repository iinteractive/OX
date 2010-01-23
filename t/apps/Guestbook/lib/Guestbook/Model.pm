package Guestbook::Model;
use Moose;

has 'posts' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { [] },
    handles => {
        'add_post' => 'push',
    }
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
