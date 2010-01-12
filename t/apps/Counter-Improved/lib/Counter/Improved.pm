package Counter::Improved;
use Moose;
use Bread::Board;

extends 'OX::Application';

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

augment 'setup_bread_board' => sub {
    container 'View' => as {
        service 'TT' => (
            class        => 'OX::View::TT',
            dependencies => {
                template_root => (service 'template_root' => (
                    block => sub {
                        (shift)->param('app_root')->subdir(qw[ root templates ])
                    },
                    dependencies => [ depends_on('/app_root') ]
                ))
            }
        );
    };
};

sub configure_router {
    my ($self, $s, $router) = @_;

    my $view = $s->param('view');

    $router->add_route('/',
        defaults => { page => 'index' },
        target   => sub {
            my $r = shift;
            $view->render( $r, 'index.tmpl', { count => $self->count } );
        }
    );

    $router->add_route('/inc',
        defaults => { page => 'inc' },
        target   => sub {
            my $r = shift;
            $self->inc_counter;
            $view->render( $r, 'index.tmpl', { count => $self->count } );
        }
    );

    $router->add_route('/dec',
        defaults => { page => 'dec' },
        target   => sub {
            my $r = shift;
            $self->dec_counter;
            $view->render( $r, 'index.tmpl', { count => $self->count } );
        }
    );

    $router->add_route('/reset',
        defaults => { page => 'reset' },
        target   => sub {
            my $r = shift;
            $self->reset_counter;
            $view->render( $r, 'index.tmpl', { count => $self->count } );
        }
    );
}

sub router_dependencies {
    +{ view => depends_on('View/TT') }
}

no Moose; no Bread::Board; 1;

__END__