package OX::Application::Resource::ControllerAction;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'OX::Application::Resource';

sub compile_route {
    my $self = shift;

    my $spec = $self->route_spec;

    my ($defaults, $validations) = ({}, {});

    foreach my $key ( keys %$spec ) {
        if (ref $spec->{ $key }) {
            $validations->{ $key } = $spec->{ $key }->{'isa'};
        }
        else {
            $defaults->{ $key } = $spec->{ $key };
        }
    }

    my $c = $self->service->param( $defaults->{controller} );
    my $a = $defaults->{action};

    return (
        $self->path,
        defaults    => $defaults,
        target      => sub { $c->$a( @_ ) },
        validations => $validations,
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::Application::Resource::ControllerAction - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::Application::Resource::ControllerAction;

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
