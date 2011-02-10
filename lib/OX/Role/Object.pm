package OX::Role::Object;
use Moose::Role;
use Bread::Board;

sub BUILD {
    my $self = shift;

    my $meta = $self->meta;

    container $self => as {
        if ($meta->has_components) {
            container Component => as {
                my $c = shift;
                $c->add_service($_) for $meta->components;
            };
        }

        if ($meta->has_config) {
            container Config => as {
                my $c = shift;
                $c->add_service($_) for $meta->config;
            };
        }

        if ($meta->has_router_config || $meta->has_router) {
            container $self->fetch('Router') => as {
                my $c = shift;
                if ($meta->has_router_config) {
                    $c->add_service($meta->router_config);
                }
                if ($meta->has_router) {
                    $c->add_service(
                        Bread::Board::Literal->new(
                            name  => 'router',
                            value => $meta->router,
                        )
                    );
                }
            };
        }

    };
}

no Moose::Role;

1;
