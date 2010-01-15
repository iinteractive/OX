package Counter::Over::Engineered::Controller;
use Moose;

has 'model' => (
    is       => 'ro',
    isa      => 'Counter::Over::Engineered::Model',
    required => 1,
);

has 'view' => (
    is       => 'ro',
    isa      => 'OX::View::Nib',
    required => 1,
);

sub index {
    my ($self, $r) = @_;
    $self->view->render( $r, 'index.tmpl' );
}

sub inc {
    my ($self, $r) = @_;
    $self->model->inc_counter;
    $self->view->render( $r, 'index.tmpl' );
}

sub dec {
    my ($self, $r) = @_;
    $self->model->dec_counter;
    $self->view->render( $r, 'index.tmpl' );
}

sub reset {
    my ($self, $r) = @_;
    $self->model->reset_counter;
    $self->view->render( $r, 'index.tmpl' );
}

sub set {
    my ($self, $r, $number) = @_;
    $self->model->set_counter( $number );
    $self->view->render( $r, 'index.tmpl' );
}

no Moose; 1;

__END__
