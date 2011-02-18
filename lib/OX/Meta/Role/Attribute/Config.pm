package OX::Meta::Role::Attribute::Config;
use Moose::Role;
Moose::Util::meta_attribute_alias('OX::Config');

after attach_to_class => sub {
    my $self = shift;
    my $meta = $self->associated_class;
    my $attr_name = $self->name;
    $meta->add_config(
        Bread::Board::BlockInjection->new(
            name => $attr_name,
            block => sub {
                my ($s, $app) = @_;
                $app->$attr_name;
            },
        )
    );
};

no Moose::Role;

1;
