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

        if ($meta->has_routes) {
            my $components = $self->get_sub_container('Component');
            service router_config => (
                block => sub {
                    +{ $meta->router_config }
                },
                $components
                    ? (dependencies => {
                          map { $_ => depends_on("/Component/$_") }
                              $components->get_service_list
                      })
                    : (),
            );
        }
    };
}

no Moose::Role;

1;
