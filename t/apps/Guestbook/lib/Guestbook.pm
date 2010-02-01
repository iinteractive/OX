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
                        'html' => sub {
                            my ($renderer, $request, $resource ) = @_;
                            $renderer->render( $request, 'index.tmpl', { this => $resource } );
                        },
                        'json' => sub {
                            my ($renderer, $request, $resource ) = @_;
                            $renderer->encode( $resource->posts );
                        },
                    }
                }
            }
        },
        dependencies => {
            guestbook => depends_on('Resources/Guestbook'),
            html      => depends_on('Transformers/HTML'),
            json      => depends_on('Transformers/JSON')
        }
    );

};

1;

__END__







