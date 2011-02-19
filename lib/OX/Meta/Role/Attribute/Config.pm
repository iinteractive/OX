package OX::Meta::Role::Attribute::Config;
use Moose::Role;
Moose::Util::meta_attribute_alias('OX::Config');

after attach_to_class => sub {
    my $self = shift;
    my $meta = $self->associated_class;
    my $attr_reader = $self->get_read_method;
    $meta->add_config(
        Bread::Board::BlockInjection->new(
            name  => $attr_reader,
            block => sub {
                my ($s, $app) = @_;
                $app->$attr_reader;
            },
        )
    );
};

no Moose::Role;

1;
