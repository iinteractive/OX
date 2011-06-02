package OX::Role::Object;
use Moose::Role;
use Bread::Board;

use Plack::App::URLMap;

sub BUILD {
    my $self = shift;

    my $meta = $self->meta;

    container $self => as {

        if ($meta->has_router_config || $meta->has_router) {
            container $self->fetch('Router') => as {
                my $c = shift;
                if ($meta->has_router) {
                    $c->add_service($meta->router->clone);
                }
                elsif ($meta->has_router_config) {
                    my $config = $meta->full_router_config;
                    for my $dep (values %{ $config->dependencies }) {
                        if (!$dep->has_service_path) {
                            $self->add_service($dep->service);
                        }
                    }
                    $c->add_service($config);
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
        my $mount = $self->meta->mount($path);
        if (exists $mount->{app}) {
            $urlmap->map($path => $mount->{app});
        }
        elsif (exists $mount->{class}) {
            my $class = $mount->{class};
            my %deps = %{ $mount->{dependencies} };
            my %params;
            for my $dep_name (keys %deps) {
                my $dep = $deps{$dep_name};
                if (!ref($dep)) {
                    $params{$dep_name} = $self->fetch($dep)->get;
                }
                elsif ($dep->isa('Bread::Board::Dependency')) {
                    $params{$dep_name} = $self->fetch($deps{$dep_name}->service_path)->get;
                }
                elsif ($dep->does('Bread::Board::Service')) {
                    $params{$dep_name} = $dep->get;
                }
                else {
                    die "Unknown dependency: $dep";
                }
            }
            my $app = $class->new(%params);
            $urlmap->map($path => $app->to_app);
        }
        else {
            die "Unknown mount spec for path $path";
        }
    }

    $urlmap->map('/' => $self->_app);

    $self->_app($urlmap->to_app);
};

around build_middleware => sub {
    my $orig = shift;
    my $self = shift;
    my $ret = $self->$orig(@_);
    unshift @$ret, $self->meta->middleware;
    return $ret;
};

no Moose::Role;

1;
