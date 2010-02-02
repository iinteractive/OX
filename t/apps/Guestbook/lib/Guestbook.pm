package Guestbook;
use Moose;
use Bread::Board;
use JSON;

extends 'OX::Application';

has '+route_builder_class' => (
    default => 'OX::Application::RouteBuilder::ResourceTransform',
);

augment 'setup_bread_board' => sub {

    container 'Transformers' => as {
        service 'HTML' => (
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
        service 'JSON' => (
            block => sub { JSON->new }
        );
    };

    container 'Resources' => as {
        service 'Guestbook' => (
            class => 'Guestbook::Resource',
        );
    };

    service 'router_config' => (
        block => sub {
            +{
                '/guestbook' => {
                    resource  => 'guestbook',
                    transform => {
                        'text/html' => sub {
                            my ($renderer, $request, $resource ) = @_;
                            $renderer->render( $request, 'index.tmpl', { this => $resource } );
                        },
                        'application/json' => sub {
                            my ($renderer, $request, $resource ) = @_;
                            $renderer->encode( $resource->posts );
                        },
                    }
                }
            }
        },
        dependencies => {
            'guestbook'        => depends_on('Resources/Guestbook'),
            'text/html'        => depends_on('Transformers/HTML'),
            'application/json' => depends_on('Transformers/JSON')
        }
    );

};

1;

__END__







