package Counter::Over::Engineered;
use Moose;
use Bread::Board;

use Path::Class 'file';

extends 'OX::Application';

with 'OX::Application::Role::RouterConfig',
     'OX::Application::Role::Router::Path::Router';

sub BUILD {
    my $self = shift;

    container $self => as {

        service app_root => (
            block => sub {
                file(__FILE__)->parent->parent->parent->parent;
            },
        );

        container 'Model' => as {
            service 'Counter' => (
                class     => 'Counter::Over::Engineered::Model',
                lifecycle => 'Singleton',
            );
        };

        container 'View' => as {
            service 'TT' => (
                class        => 'Counter::Over::Engineered::View',
                dependencies => {
                    template_root => (service 'template_root' => (
                        block => sub {
                            (shift)->param('app_root')->subdir(qw[ root templates ])
                        },
                        dependencies => [ '/app_root' ]
                    ))
                }
            );
        };

        container 'Controller' => as {
            service 'Root' => (
                class        => 'Counter::Over::Engineered::Controller',
                dependencies => {
                    view  => '/View/TT',
                    model => '/Model/Counter',
                }
            );
        };

        service 'RouterConfig' => (
            block => sub {
                +{
                    '/' => {
                        controller => '/Controller/Root',
                        action     => 'index',
                    },
                    '/inc' => {
                        controller => '/Controller/Root',
                        action     => 'inc',
                    },
                    '/dec' => {
                        controller => '/Controller/Root',
                        action     => 'dec',
                    },
                    '/reset' => {
                        controller => '/Controller/Root',
                        action     => 'reset',
                    },
                    '/set/:number' => {
                        controller => '/Controller/Root',
                        action     => 'set',
                        number     => { isa => 'Int' }
                    },
                }
            },
        );
    };
}


no Moose; no Bread::Board; 1;

__END__
