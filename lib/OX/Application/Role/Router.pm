package OX::Application::Role::Router;
use Moose::Role;
use namespace::autoclean;

use Bread::Board;
use Class::Load 'load_class';

requires qw(router_class app_from_router);

sub BUILD { }
before BUILD => sub {
    my $self = shift;

    load_class($self->request_class);

    container $self => as {
        service Router => (
            class => $self->router_class,
            block => sub {
                my $s = shift;
                my $router = $self->build_router($s);
                $self->configure_router($router);
                return $router;
            },
            dependencies => $self->router_dependencies,
        );
    };
};

sub router { shift->resolve(service => 'Router') }

sub build_router {
    my $self = shift;
    my ($s) = @_;
    my $router_class = $self->router_class;
    load_class($router_class);
    return $router_class->new(%{ $s->params });
}
sub configure_router { }
sub router_dependencies { {} }

around build_middleware => sub {
    my $orig = shift;
    my $self = shift;
    my ($s) = @_;

    my $router = $s->param('Router');

    return [
        sub {
            my $app = shift;
            return sub {
                my $env = shift;
                # not just using plack.router (set by Plack::App::Path::Router)
                # because we want this to be accessible to user middleware
                $env->{'ox.router'} = $router;
                $app->($env);
            }
        },
        @{ $self->$orig(@_) },
    ];
};
around middleware_dependencies => sub {
    my $orig = shift;
    my $self = shift;

    return {
        %{ $self->$orig(@_) },
        Router => 'Router',
    };
};

sub build_app {
    my $self = shift;
    my ($s) = @_;

    return $self->app_from_router($s->param('Router'));
}
around app_dependencies => sub {
    my $orig = shift;
    my $self = shift;
    return {
        %{ $self->$orig(@_) },
        Router => 'Router',
    };
};

sub request_class { 'OX::Request' }
sub new_request {
    my $self = shift;
    my ($env) = @_;

    return $self->request_class->new(env => $env);
}

sub handle_response {
    my $self = shift;
    my ($res, $req) = @_;

    if (!ref($res)) {
        $res = $req->new_response([
            200, [ 'Content-Type' => 'text/html' ], [ $res ]
        ]);
    }
    elsif (!blessed($res) || !$res->can('finalize')) {
        $res = $req->new_response($res);
    }

    return $res->finalize;
}

1;
