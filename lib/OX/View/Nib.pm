package OX::View::Nib;
use Moose;

use OX::View::Nib::Outlet;

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

    # TODO:
    # Fix the whole bunch of this,
    # the current form is a quick
    # hack to get done for the talk
    # - SL

    $params->{outlet} = sub {
        OX::View::Nib::Outlet->new( @_ )->resolve( $self->responder )
    };

    $params->{action} = sub {
        my $spec = shift;
        my $body = delete $spec->{body};
        my $type = delete $spec->{type};
        # TODO:
        # delegate this correctly ..
        # - SL
        if ($type eq 'link') {

            my ($full_name, $controller, $action);
            my $additional = {};

            if (ref $spec->{bind_to}) {
                ($full_name)  =   keys %{ $spec->{bind_to} };
                ($additional) = values %{ $spec->{bind_to} };
            }
            else {
                $full_name = $spec->{bind_to};
            }

            if ( $full_name =~ /\// ) {
                ($controller, $action) = split /\// => $full_name;
            }
            else {
                $action = $full_name;
            }

            my $route = {
                controller => $controller,
                action     => $action,
                %$additional
            };

            return '<a href="'
                 . $r->uri_for( $route )
                 . '">'
                 . $body
                 . '</a>';
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
