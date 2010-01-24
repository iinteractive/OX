package Guestbook::Controller;
use Moose;

has 'model' => (
    is       => 'ro',
    isa      => 'Guestbook::Model',
    required => 1,
);

has 'view' => (
    is       => 'ro',
    isa      => 'OX::View::Nib',
    required => 1,
);

sub index {
    my ($self, $r) = @_;
    $self->redirect_to_list( $r );
}

sub list {
    my ($self, $r) = @_;
    $self->view->render( $r, 'index.tmpl' );
}

sub post {
    my ($self, $r) = @_;
    $self->model->add_post( $r->param('note') );
    $self->redirect_to_list( $r );
}

sub redirect_to_list {
    my ($self, $r) = @_;
    my $resp = $r->new_response;
    $resp->redirect( $r->uri_for( { controller => 'root', action => 'list' } ) );
    $resp;
}

no Moose; 1;

__END__
