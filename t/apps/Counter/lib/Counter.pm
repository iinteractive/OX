package Counter;
use Moose;

extends 'OX::Application';
with 'OX::Application::Role::Router::Path::Router';

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

sub configure_router {
    my ($self, $router) = @_;

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

    [
        200,
        [ 'Content-type' => 'text/html' ],
        [qq{
            <html>
                <head><title>OX - Counter Example</title>
                <body>
                    <h1>${ \$self->count }</h1>
                    <hr/>
                    <a href="${ \$request->uri_for({page => 'inc'}) }">++</a>
                    &nbsp;&nbsp;|&nbsp;&nbsp;
                    <a href="${ \$request->uri_for({page => 'dec'}) }">--</a>
                    &nbsp;&nbsp;|&nbsp;&nbsp;
                    <a href="${ \$request->uri_for({page => 'reset'}) }">reset</a>
                </body>
            </html>
        }]
    ]
}

no Moose; 1;

__END__
