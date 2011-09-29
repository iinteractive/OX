package Counter::Over::Engineered::Sugar;
use OX;

use MooseX::Types::Path::Class;

has template_root => (
    is     => 'ro',
    isa    => 'Path::Class::Dir',
    coerce => 1,
    block  => sub {
        Path::Class::File->new(__FILE__)->parent->parent->parent->parent->parent->subdir(qw[ root templates ]);
    },
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

has root => (
    is    => 'ro',
    isa   => 'Counter::Over::Engineered::Sugar::Controller',
    infer => 1,
);

router as {
    route '/'            => 'root.index';
    route '/inc'         => 'root.inc';
    route '/dec'         => 'root.dec';
    route '/reset'       => 'root.reset';
    route '/set/:number' => 'root.set' => (
        number => { isa => 'Int' },
    );
};

no OX;

1;
