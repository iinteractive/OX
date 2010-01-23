package OX::View::Nib;
use Moose;

use OX::View::Nib::Outlet::Text;
use OX::View::Nib::Action::Link;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'OX::View::TT';

has 'responder' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

override 'build_template_params' => sub {
    my $self   = shift;
    my $r      = shift;
    my $params = super();

    $params->{outlet} = sub {
        my $spec = shift;
        my $type = delete $spec->{type};
        if ($type eq 'text') {
            OX::View::Nib::Outlet::Text->new( $spec )->resolve( $self )
        }
        else {
            confess "Unknown outlet type ($type)";
        }
    };

    $params->{action} = sub {
        my $spec = shift;
        my $type = delete $spec->{type};
        if ($type eq 'link') {
            OX::View::Nib::Action::Link->new( $spec )->resolve( $self, $r )
        }
        else {
            confess "Unknown action type ($type)";
        }
    };

    $params;
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::View::Nib - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::View::Nib;

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
