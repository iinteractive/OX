package OX::RouteBuilder;
use Moose::Role;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'path' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'route_spec' => (
    is       => 'ro',
    required => 1,
);

has 'service' => (
    is       => 'ro',
    isa      => 'Bread::Board::Service',
    required => 1
);

has params => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub extract_defaults_and_validations {
    my ($self, $params) = @_;

    my ($defaults, $validations) = ({}, {});

    foreach my $key ( keys %$params ) {
        if (ref $params->{ $key }) {
            $validations->{ $key } = $params->{ $key }->{'isa'};
        }
        else {
            $defaults->{ $key } = $params->{ $key };
        }
    }

    return ($defaults, $validations);
}

requires 'compile_routes';

no Moose::Role; 1;

__END__

=pod

=head1 NAME

OX::RouteBuilder - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::RouteBuilder;

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
