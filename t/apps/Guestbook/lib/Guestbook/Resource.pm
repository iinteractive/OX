package Guestbook::Resource;
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

sub resolve {
    my ($self, $r) = @_;
    +{
        GET  => sub {
            $self->view->render( $r, 'index.tmpl' );
        },
        POST => sub {
            $self->model->add_post( $r->param('note') );
            my $uri = $r->uri->clone;
            $uri->query( undef );
            my $resp = $r->new_response;
            $resp->redirect( $uri );
            $resp;
        }
    };
}

no Moose; 1;

__END__








