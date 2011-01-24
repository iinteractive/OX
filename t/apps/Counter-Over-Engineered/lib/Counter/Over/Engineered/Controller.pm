package Counter::Over::Engineered::Controller;
use Moose;

has 'model' => (
    is       => 'ro',
    isa      => 'Counter::Over::Engineered::Model',
    required => 1,
);

has 'view' => (
    is       => 'ro',
    isa      => 'Counter::Over::Engineered::View',
    required => 1,
);

sub index {
    my ($self, $r) = @_;
    $self->render( $r );
}

sub inc {
    my ($self, $r) = @_;
    $self->model->inc_counter;
    $self->render( $r );
}

sub dec {
    my ($self, $r) = @_;
    $self->model->dec_counter;
    $self->render( $r );
}

sub reset {
    my ($self, $r) = @_;
    $self->model->reset_counter;
    $self->render( $r );
}

sub set {
    my ($self, $r, $number) = @_;
    $self->model->set_counter( $number );
    $self->render( $r );
}

sub render {
    my ($self, $r) = @_;
    $self->view->render( $r, 'index.tmpl', { this => $self } );
}

no Moose; 1;

__END__
