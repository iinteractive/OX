package OX::Util;
use strict;
use warnings;

# move to Path::Router?
sub canonicalize_path {
    my ($path) = @_;
    return join '/', map { /^\??:/ ? ':' : $_ } split '/', $path, -1;
}

1;
