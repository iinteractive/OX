package Counter::Over::Engineered::Sugar;
use OX;

use MooseX::Types::Path::Class;

with 'OX::Role::WithAppRoot';

has template_root => (
    is     => 'ro',
    isa    => 'Path::Class::Dir',
    coerce => 1,
    block  => sub {
        (shift)->param('app_root')->subdir(qw[ root templates ])
    },
    dependencies => ['app_root'],
);

has counter => (
    is        => 'ro',
    isa       => 'Counter::Over::Engineered::Sugar::Model',
    lifecycle => 'Singleton',
);

has tt => (
    is           => 'ro',
    isa          => 'Counter::Over::Engineered::Sugar::View',
    dependencies => ['template_root'],
);

has counter_controller => (
    is           => 'ro',
    isa          => 'Counter::Over::Engineered::Sugar::Controller',
    dependencies => {
        view  => 'tt',
        model => 'counter',
    },
);

router as {
    route '/'            => 'root.index';
    route '/inc'         => 'root.inc';
    route '/dec'         => 'root.dec';
    route '/reset'       => 'root.reset';
    route '/set/:number' => 'root.set' => (
        number => { isa => 'Int' },
    );
}, (root => depends_on('counter_controller'));

no OX;

1;
