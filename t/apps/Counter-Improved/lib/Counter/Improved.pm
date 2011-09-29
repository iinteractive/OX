package Counter::Improved;
use Moose;
use Bread::Board;

use Path::Class 'file';

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

sub BUILD {
    my $self = shift;
    container $self => as {
        service 'app_root' => (
            block => sub {
                file(__FILE__)->parent->parent->parent
            },
        );

        container 'View' => as {
            service 'TT' => (
                class        => 'Template',
                dependencies => {
                    INCLUDE_PATH => (service 'template_root' => (
                        block => sub {
                            (shift)->param('app_root')->subdir(qw[ root templates ])
                        },
                        dependencies => [ '/app_root' ]
                    ))
                }
            );
        };
    }
}

sub configure_router {
    my ($self, $router) = @_;

    my $view = $self->resolve(service => 'View/TT');

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

no Moose; no Bread::Board; 1;

__END__
