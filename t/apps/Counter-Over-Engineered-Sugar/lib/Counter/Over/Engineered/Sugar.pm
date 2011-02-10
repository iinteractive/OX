package Counter::Over::Engineered::Sugar;
use OX;

with 'OX::Role::WithAppRoot';

config template_root => sub {
    (shift)->param('app_root')->subdir(qw[ root templates ])
}, (app_root => depends_on('/app_root'));

component Counter => {
    class     => 'Counter::Over::Engineered::Sugar::Model',
    lifecycle => 'Singleton',
};
component TT => 'Counter::Over::Engineered::Sugar::View' => (
    template_root => depends_on('/Config/template_root'),
);
component CounterController => 'Counter::Over::Engineered::Sugar::Controller' => (
    view  => depends_on('/Component/TT'),
    model => depends_on('/Component/Counter')
);

router as {
    route '/'            => 'root.index';
    route '/inc'         => 'root.inc';
    route '/dec'         => 'root.dec';
    route '/reset'       => 'root.reset';
    route '/set/:number' => 'root.set' => (
        number => { isa => 'Int' },
    );
}, (root => depends_on('/Component/CounterController'));

no OX;
1;

__END__
