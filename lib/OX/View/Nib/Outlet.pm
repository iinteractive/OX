package OX::View::Nib::Outlet;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'binding' => (
    init_arg => 'bind_to',
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub locate_bound_element {
    my ($self, $binding, $object) = @_;

    my ($method, @binding) = split /\// => $binding;

    my $result = $object->$method;

    while ($method = shift @binding) {
        $result = $result->$method;
    }

    $result;
}

requires 'resolve';

no Moose::Role; 1;

__END__

=pod

=head1 NAME

OX::View::Nib::Outlet - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::View::Nib::Outlet;

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
