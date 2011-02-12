package OX::Role::Object;
use Moose::Role;
use Bread::Board;

use Plack::App::URLMap;

sub BUILD {
    my $self = shift;

    my $meta = $self->meta;

    container $self => as {
        if ($meta->has_components) {
            container Component => as {
                my $c = shift;
                for my $component ($meta->components) {
                    if ($component->isa('Bread::Board::BlockInjection')) {
                        my $block = $component->block;
                        $component->block(sub {
                            $block->(@_, $self);
                        });
                    }
                    $c->add_service($component);
                }
            };
        }

        if ($meta->has_config) {
            container Config => as {
                my $c = shift;
                for my $config ($meta->config) {
                    if ($config->isa('Bread::Board::BlockInjection')) {
                        my $block = $config->block;
                        $config->block(sub {
                            $block->(@_, $self);
                        });
                    }
                    $c->add_service($config);
                }
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

after prepare_app => sub {
    my $self = shift;

    return unless $self->meta->has_mounts;

    my $urlmap = Plack::App::URLMap->new;

    for my $path ($self->meta->mount_paths) {
        my $class = $self->meta->mount($path)->{class};
        my %deps = %{ $self->meta->mount($path)->{dependencies} };
        my %params;
        for my $dep_name (keys %deps) {
            $params{$dep_name} = $self->fetch($deps{$dep_name}->service_path)->get;
        }
        my $app = $class->new(%params);
        $urlmap->map($path => $app->to_app);
    }

    $urlmap->map('/' => $self->_app);

    $self->_app($urlmap->to_app);
};

no Moose::Role;

1;
