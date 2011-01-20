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

        if ($meta->has_resources) {
            container Resource => as {
                $Bread::Board::CC->add_service($_) for $meta->resources;
            };
        }

        if ($meta->has_config) {
            container Config => as {
                $Bread::Board::CC->add_service($_) for $meta->config;
            };
        }

        if ($meta->has_routes) {
            my $resource_container = $self->get_sub_container('Resource');
            service router_config => (
                block => sub {
                    +{ $meta->router_config }
                },
                $resource_container
                    ? (dependencies => {
                          map { $_ => depends_on("/Resource/$_") }
                              $resource_container->get_service_list
                      })
                    : (),
            );
        }
    };
}

no Moose::Role;

1;
