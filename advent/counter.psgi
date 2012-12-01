package Counter::Model;
use Moose;

has counter => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        inc   => 'inc',
        dec   => 'dec',
        reset => 'reset',
    },
);

package Counter::Controller;
use Moose;

has model => (
    is       => 'ro',
    isa      => 'Counter::Model',
    required => 1,
);

sub index {
    my $self = shift;
    return $self->model->counter;
}

sub inc {
    my $self = shift;
    return $self->model->inc;
}

sub dec {
    my $self = shift;
    return $self->model->dec;
}

sub reset {
    my $self = shift;
    return $self->model->reset;
}

package Counter;
use OX;

has model => (
    is        => 'ro',
    isa       => 'Counter::Model',
    lifecycle => 'Singleton',
);

has controller => (
    is    => 'ro',
    isa   => 'Counter::Controller',
    infer => 1,
);

router as {
    route '/'      => 'controller.index';
    route '/inc'   => 'controller.inc';
    route '/dec'   => 'controller.dec';
    route '/reset' => 'controller.reset';
};
