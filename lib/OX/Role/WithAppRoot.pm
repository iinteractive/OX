package OX::Role::WithAppRoot;
use Moose::Role;
use Bread::Board::Declare; # XXX: OX::Role?

use Class::Inspector;
use MooseX::Types::Path::Class;
use Path::Class;

has app_root => (
    is     => 'ro',
    isa    => 'Path::Class::Dir',
    coerce => 1,
    block  => sub {
        my ($s, $self) = @_;
        my $class = $self->meta->name;
        my $root  = file(Class::Inspector->resolved_filename($class));
        # climb out of the lib/ directory
        $root = $root->parent foreach split /\:\:/ => $class;
        $root = $root->parent; # one last time for lib/
        $root;
    },
);

no Moose::Role;

1;
