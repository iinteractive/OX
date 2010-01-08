package Counter2;
use Moose;

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

has 'view' => (
    is       => 'ro',
    isa      => 'OX::View::TT',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        OX::View::TT->new(
            template_root => $self->fetch_service('root')->subdir(qw[ root templates ])
        )
    }
);

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
    $self->view->render($request, 'index.tmpl' => { count => $self->count });
}

no Moose; 1;

__END__