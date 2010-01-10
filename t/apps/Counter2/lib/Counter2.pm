package Counter2;
use Moose;

use Bread::Board;
use OX::View::TT;

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
    my $self = shift;

    service 'template_root' => (
        block => sub {
            (shift)->param('app_root')->subdir(qw[ root templates ])
        },
        dependencies => [ depends_on('app_root') ]
    );

    service 'View' => (
        class        => 'OX::View::TT',
        dependencies => [ depends_on('template_root') ]
    );
};

sub configure_router {
    my ($self, $s, $router) = @_;

    $router->add_route('/',
        defaults => { page => 'index' },
        target   => sub { $self->render_view( undef, @_ ) }
    );

    $router->add_route('/inc',
        defaults => { page => 'inc' },
        target   => sub { $self->render_view('inc_counter', @_ ) }
    );

    $router->add_route('/dec',
        defaults => { page => 'dec' },
        target   => sub { $self->render_view('dec_counter', @_ ) }
    );

    $router->add_route('/reset',
        defaults => { page => 'reset' },
        target   => sub { $self->render_view('reset_counter', @_ ) }
    );
}

sub render_view {
    my ($self, $method, $request) = @_;
    $self->$method() if $method;
    $self->fetch_service('View')->render($request, 'index.tmpl' => { count => $self->count });
}

no Moose; no Bread::Board; 1;

__END__