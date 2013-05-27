package OX::Application::Role::Sugar;
use Moose::Role;
use namespace::autoclean;

use Bread::Board;
use Plack::App::URLMap;

use OX::Util;

has _manual_router_config => (
    is  => 'rw',
    isa => 'HashRef',
);

sub BUILD { }
after BUILD => sub {
    my $self = shift;

    my $manual_router_config = $self->has_service('RouterConfig')
        ? $self->resolve(service => 'RouterConfig')
        : {};
    $self->_manual_router_config($manual_router_config);

    $self->regenerate_router_config;
};

sub regenerate_router_config {
    my $self = shift;

    my $manual_router_config = $self->_manual_router_config;
    my $sugar_router_config = $self->meta->router_config;

    container $self => as {
        service RouterConfig => {
            %$manual_router_config,
            %$sugar_router_config,
        };
    };
}

around build_middleware => sub {
    my $orig = shift;
    my $self = shift;

    my @middleware = map { $_->resolve($self) } $self->meta->all_middleware;

    return [
        @{ $self->$orig(@_) },
        @middleware,
    ];
};

around build_app => sub {
    my $orig = shift;
    my $self = shift;

    my $app = $self->$orig(@_);
    return $app unless $self->meta->has_mounts;

    my $urlmap = Plack::App::URLMap->new;

    for my $mount ($self->meta->mounts) {
        if ($mount->isa('OX::Meta::Mount::App')) {
            $urlmap->map($mount->path => $mount->app);
        }
        elsif ($mount->isa('OX::Meta::Mount::Class')) {
            my $service = Bread::Board::ConstructorInjection->new(
                name         => '__ANON__',
                class        => $mount->class,
                dependencies => $mount->dependencies,
                parent       => $self,
            );
            my $app = $service->get;
            $urlmap->map($mount->path => $app->to_app);
        }
        else {
            die "Unknown mount type for path " . $mount->path . ": "
              . blessed($mount);
        }
    }

    $urlmap->map('/' => $app)
        unless $self->meta->has_mount_for('/');

    return $urlmap->to_app;
};

around to_app => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        unless $self->meta->needs_reresolve;

    # need to re-resolve for every request, to ensure that middleware
    # dependencies are correct - otherwise, a middleware that depends on a
    # service in an app will only resolve it once, at to_app time
    return sub {
        my ($env) = @_;
        $self->$orig(@_)->($env);
    };
};

=pod

=for Pod::Coverage
  BUILD
  regenerate_router_config

=cut

1;
