package OX::Request;
use Moose;
use MooseX::NonMoose;

use OX::Response;

extends 'Plack::Request';

sub BUILDARGS {
    return {};
}

sub router { (shift)->env->{'ox.router'} }

sub mapping {
    my $self = shift;
    my $match = $self->env->{'plack.router.match'};
    return unless $match;
    return %{ $match->mapping };
}

sub uri_for {
    my ($self, $route) = @_;
    my $uri_base = $self->script_name || '/';
    $uri_base .= '/' unless $uri_base =~ m+/$+;
    return $uri_base . $self->router->uri_for( %$route );
}

sub new_response {
    my $self = shift;
    OX::Response->new( @_ );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::Request - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::Request;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
