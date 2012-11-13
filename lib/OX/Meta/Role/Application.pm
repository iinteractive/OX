package OX::Meta::Role::Application;
use Moose::Role;
use namespace::autoclean;

requires '_apply_routes';

after apply => sub {
    my $self = shift;
    my ($role, $class) = @_;

    $self->_apply_routes($role, $class);
};

1;
