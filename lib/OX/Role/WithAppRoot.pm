package OX::Role::WithAppRoot;
use Moose::Role;
use Bread::Board;

use Bread::Board::Container;
use Bread::Board::Literal;
use Class::Inspector;
use Path::Class;

has _app_root_path => (
    is      => 'ro',
    isa     => 'Str',
    default => 'app_root',
);

after BUILD => sub {
    my $self = shift;

    # XXX: push this back into Bread::Board?
    # $container->find_or_create_path or something
    my @path = split m+/+, $self->_app_root_path;
    my $service_name = pop @path;

    my $container = $self;
    while (@path) {
        my $subcontainer_name = shift @path;
        next if !length($subcontainer_name);
        my $subcontainer = $container->fetch($subcontainer_name);
        if (!defined $subcontainer) {
            $subcontainer = Bread::Board::Container->new(
                name => $subcontainer_name
            );
        }
        $container = $subcontainer;
    }

    container $container => as {

        service $service_name => do {
            my $class = $self->meta->name;
            my $root  = file(Class::Inspector->resolved_filename($class));
            # climb out of the lib/ directory
            $root = $root->parent foreach split /\:\:/ => $class;
            $root = $root->parent; # one last time for lib/
            $root;
        };

    };
};

no Bread::Board;
no Moose::Role;

1;
