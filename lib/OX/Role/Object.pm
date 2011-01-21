package OX::Role::Object;
use Moose::Role;
use Bread::Board;

sub BUILD {
    my $self = shift;

    my $meta = $self->meta;

    container $self => as {
        if ($meta->has_components) {
            container Component => as {
                $Bread::Board::CC->add_service($_) for $meta->components;
            };
        }

        if ($meta->has_config) {
            container Config => as {
                $Bread::Board::CC->add_service($_) for $meta->config;
            };
        }

        if ($meta->has_router_config) {
            $Bread::Board::CC->add_service($meta->router_config);
        }

        if ($meta->has_router) {
            $Bread::Board::CC->add_service(
                Bread::Board::Literal->new(
                    name  => 'Router',
                    value => $meta->router,
                )
            );
        }
    };
}

no Moose::Role;

1;
