package OX::Web::Request;
use Moose;
use MooseX::NonMoose;

use OX::Web::Response;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Plack::Request';

sub BUILDARGS {
    return {};
}

sub router { (shift)->env->{'plack.router'} }

sub uri_for {
    my ($self, $route) = @_;
    $self->router->uri_for( %$route );
}

sub new_response {
    my $self = shift;
    OX::Web::Response->new( @_ );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::Web::Request - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::Web::Request;

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
