package OX::Application::RouteBuilder::ResourceTransform;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'OX::Application::RouteBuilder';

sub compile_routes {
    my $self = shift;

    my $spec = $self->route_spec;

    my $transformations = delete $spec->{transform};
    my $resource        = $self->service->param( $spec->{resource} );

    my ($defaults, $validations) = $self->extract_defaults_and_validations( $spec );

    my @routes;

    foreach my $transform_type ( keys %$transformations ) {

        my $new_path    = $self->path . '.' . $transform_type;
        my $transformer = $transformations->{ $transform_type };
        my $renderer    = $self->service->param( $transform_type );

        push @routes => [
            $new_path,
            defaults    => { %$defaults, transform => $transform_type },
            validations => $validations,
            target      => sub {
                my $request  = shift;
                my $resolved = $resource->resolve;

                return [ 500, [ 'Content-Type' => 'text/plain' ], [ 'No ' . $request->method . ' method found for resource' ] ]
                    unless exists $resolved->{ $request->method };

                my $response = $resolved->{ $request->method }->( $request );

                return [ 500, [ 'Content-Type' => 'text/plain' ], [ 'Method ' . $request->method . ' returned a false value' ] ]
                    if not $response;

                return $response
                    if blessed $response && $response->isa('OX::Web::Response');

                return $transformer->( $renderer, $resource, $request );
            }
        ]
    }


    return @routes;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::Application::RouteBuilder::ResourceTransform - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::Application::RouteBuilder::ResourceTransform;

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
