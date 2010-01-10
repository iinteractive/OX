package Counter::Over::Engineered;
use Moose;
use Bread::Board;

extends 'OX::Application';

augment 'setup_bread_board' => sub {

    service 'template_root' => (
        block => sub {
            (shift)->param('app_root')->subdir(qw[ root templates ])
        },
        dependencies => [ depends_on('app_root') ]
    );

    container 'View' => as {
        service 'TT' => (
            class        => 'OX::View::TT',
            dependencies => [ depends_on('/template_root') ]
        );
    };

    container 'Controller' => as {
        service 'Root' => (
            class        => 'Counter::Over::Engineered::Controller',
            dependencies => {
                view => depends_on('/View/TT')
            }
        );
    };

};

sub configure_router {
    my ($self, $s, $router) = @_;

    my $c = $s->param('root_controller');

    $router->add_route('/',
        defaults => {
            controller => 'root',
            action     => 'index',
        },
        target   => sub { $c->index( @_ ) }
    );

    $router->add_route('/inc',
        defaults => {
            controller => 'root',
            action     => 'inc',
        },
        target   => sub { $c->inc( @_ ) }
    );

    $router->add_route('/dec',
        defaults => {
            controller => 'root',
            action     => 'dec',
        },
        target   => sub { $c->dec( @_ ) }
    );

    $router->add_route('/reset',
        defaults => {
            controller => 'root',
            action     => 'reset',
        },
        target   => sub { $c->reset( @_ ) }
    );
}

sub router_dependencies {
    +{ root_controller => depends_on('/Controller/Root') }
}

no Moose; no Bread::Board; 1;

__END__