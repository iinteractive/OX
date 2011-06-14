package OX::Router::Path::Router::Route;
use Moose;
use namespace::autoclean;

extends 'Path::Router::Route';

has '+target' => (
    writer => '_set_target',
);

sub BUILD {
    my $self = shift;

    if ($self->has_target) {
        my $target = $self->target;
        $self->_set_target(sub {
            my $env = shift;
            my $req = $env->{'plack.router'}->new_request($env);

            my $res = $target->($req, @{ $env->{'plack.router.match.args'} });

            if (blessed $res && $res->can('finalize')) {
                return $res->finalize;
            }
            elsif (!ref $res) {
                return [ 200, [ 'Content-Type' => 'text/html' ], [ $res ] ];
            }
            else {
                return $res;
            }
        });
    }
}

__PACKAGE__->meta->make_immutable;

1;
