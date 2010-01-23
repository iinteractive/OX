package OX::View::Nib::Action::Link;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'OX::View::Nib::Action';

has 'body' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub resolve {
    my ($self, $nib, $request) = @_;
    return '<a href="'
         . $request->uri_for( $self->binding )
         . '">'
         . $self->body
         . '</a>';
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::View::Nib::Action::Link - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::View::Nib::Action::Link;

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
