package Counter::Over::Engineered::Controller;
use Moose;

has 'count' => (
    traits  => [ 'Counter' ],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_counter   => 'inc',
        dec_counter   => 'dec',
        reset_counter => 'reset',
        set_counter   => 'set'
    }
);

has 'view' => (
    is       => 'ro',
    isa      => 'OX::View::TT',
    required => 1,
);

sub index {
    my ($self, $r) = @_;
    $self->view->render( $r, 'index.tmpl', { count => $self->count } );
}

sub inc {
    my ($self, $r) = @_;
    $self->inc_counter;
    $self->view->render( $r, 'index.tmpl', { count => $self->count } );
}

sub dec {
    my ($self, $r) = @_;
    $self->dec_counter;
    $self->view->render( $r, 'index.tmpl', { count => $self->count } );
}

sub reset {
    my ($self, $r) = @_;
    $self->reset_counter;
    $self->view->render( $r, 'index.tmpl', { count => $self->count } );
}

sub set {
    my ($self, $r, $number) = @_;
    $self->set_counter( $number );
    $self->view->render( $r, 'index.tmpl', { count => $self->count } );
}

no Moose; 1;

__END__
