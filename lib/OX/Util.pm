package OX::Util;
use strict;
use warnings;

use Moose::Util::TypeConstraints 'match_on_type';

use OX::Types;

# move to Path::Router?
sub canonicalize_path {
    my ($path) = @_;
    return join '/', map { /^\??:/ ? ':' : $_ } split '/', $path, -1;
}

sub apply_middleware {
    my ($app, $middleware) = @_;

    match_on_type $middleware => (
        'CodeRef' => sub {
            $middleware->($app);
        },
        'OX::Types::MiddlewareClass' => sub {
            $middleware->wrap($app);
        },
        'Plack::Middleware' => sub {
            $middleware->wrap($app);
        },
        sub {
            warn "not applying middleware $middleware!";
            $app;
        },
    );
}

=for Pod::Coverage
  canonicalize_path

=cut

1;
