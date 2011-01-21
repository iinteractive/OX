package OX::Router::Route;
use Moose;

extends 'Path::Router::Route';

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    if (exists $args->{target}) {
        my $target = $args->{target};
        $args->{target} = sub {
            my $env = shift;
            my $req = OX::Web::Request->new($env);

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
        };
    }

    return $args;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
