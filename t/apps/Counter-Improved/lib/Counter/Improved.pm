package Counter::Improved;
use Moose;
use Bread::Board;

extends 'OX::Application';

with 'OX::Role::WithAppRoot';

has 'count' => (
    traits  => [ 'Counter' ],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_counter   => 'inc',
        dec_counter   => 'dec',
        reset_counter => 'reset',
    }
);

sub BUILD {
    my $self = shift;
    container $self => as {
        container 'View' => as {
            service 'TT' => (
                class        => 'Template',
                dependencies => {
                    INCLUDE_PATH => (service 'template_root' => (
                        block => sub {
                            (shift)->param('app_root')->subdir(qw[ root templates ])
                        },
                        dependencies => [ depends_on('/app_root') ]
                    ))
                }
            );
        };
    }
}

sub configure_router {
    my ($self, $s, $router) = @_;

    my $view = $s->param('view');

    $router->add_route('/',
        defaults => { page => 'index' },
        target   => sub {
            my $r = shift;
            my $out;
            $view->process( 'index.tmpl', { count => $self->count }, \$out );
            $out;
        }
    );

    $router->add_route('/inc',
        defaults => { page => 'inc' },
        target   => sub {
            my $r = shift;
            $self->inc_counter;
            my $out;
            $view->process( 'index.tmpl', { count => $self->count }, \$out );
            $out;
        }
    );

    $router->add_route('/dec',
        defaults => { page => 'dec' },
        target   => sub {
            my $r = shift;
            $self->dec_counter;
            my $out;
            $view->process( 'index.tmpl', { count => $self->count }, \$out );
            $out;
        }
    );

    $router->add_route('/reset',
        defaults => { page => 'reset' },
        target   => sub {
            my $r = shift;
            $self->reset_counter;
            my $out;
            $view->process( 'index.tmpl', { count => $self->count }, \$out );
            $out;
        }
    );
}

sub router_dependencies {
    +{ view => depends_on('/View/TT') }
}

no Moose; no Bread::Board; 1;

__END__
