package OX::Router::Path::Router::Route;
use Moose;
use namespace::autoclean;

use Plack::Util;

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

            my $psgi_res;
            if (blessed $res && $res->can('finalize')) {
                $psgi_res = $res->finalize;
            }
            elsif (!ref $res) {
                $psgi_res = [ 200, [ 'Content-Type' => 'text/html' ], [ $res ] ];
            }
            else {
                $psgi_res = $res;
            }

            Plack::Util::response_cb($psgi_res, sub {
                my $res = shift;
                return sub {
                    my $chunk = shift;
                    return unless defined $chunk;
                    return $req->encode($chunk);
                };
            });

            return $psgi_res;
        });
    }
}

__PACKAGE__->meta->make_immutable;

1;
