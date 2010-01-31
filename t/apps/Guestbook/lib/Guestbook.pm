package Guestbook;
use Moose;
use Bread::Board;

extends 'OX::Application';

augment 'setup_bread_board' => sub {

    container 'Model' => as {
        service 'Posts' => (
            class => 'Guestbook::Model'
        );
    };

    container 'View' => as {
        service 'Nib' => (
            class        => 'OX::View::Nib',
            dependencies => {
                template_root => (service 'template_root' => (
                    block        => sub { (shift)->param('app_root')->subdir(qw[ root templates ]) },
                    dependencies => [ depends_on('/app_root') ]
                )),
                responder => depends_on('/Resources/Guestbook')
            }
        );
    };

    container 'Resources' => as {
        service 'Guestbook' => (
            class        => 'Guestbook::Resource',
            dependencies => {
                view  => depends_on('/View/Nib'),
                model => depends_on('/Model/Posts')
            }
        );
    };

};

sub configure_router {
    my ($self, $s, $router) = @_;

    my $guestbook = $s->param('guestbook');

    $router->add_route('/',
        defaults => { resource => 'guestbook' },
        target   => sub {
            my $r = shift;
            $guestbook->resolve( $r )->{ $r->method }->();
        }
    );
}

sub router_dependencies {
    +{ guestbook => depends_on('Resources/Guestbook') }
}

1;

__END__