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
                responder => depends_on('/Controller/Root')
            }
        );
    };

    container 'Controller' => as {
        service 'Root' => (
            class        => 'Guestbook::Controller',
            dependencies => {
                view  => depends_on('/View/Nib'),
                model => depends_on('/Model/Posts')
            }
        );
    };

    service 'router_config' => (
        block => sub {
            +{
                '/' => {
                    controller => 'root',
                    action     => 'index',
                },
                '/list' => {
                    controller => 'root',
                    action     => 'list',
                },
                '/post' => {
                    controller => 'root',
                    action     => 'post',
                },
            }
        },
        dependencies => {
            root => depends_on('/Controller/Root')
        }
    );

};

1;

__END__