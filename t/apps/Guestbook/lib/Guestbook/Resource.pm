package Guestbook::Resource;
use Moose;

has 'posts' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { [] },
    handles => {
        'add_post' => 'push',
    }
);

sub resolve {
    my $self = shift;
    +{
        GET  => sub { $self },
        POST => sub {
            my $r = shift;
            $self->add_post( $r->param('note') );

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








