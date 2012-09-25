package OX::RouteBuilder;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: abstract role for classes that turn configuration into a route

=head1 DESCRIPTION

This is an abstract role which is used to turn simplified and easy to
understand routing descriptions into actual routes that the router understands.
Currently, the API is a bit specific to L<Path::Router>.

For usable examples, see L<OX::RouteBuilder::ControllerAction>,
L<OX::RouteBuilder::HTTPMethod>, and L<OX::RouteBuilder::Code>.

=cut

=method compile_routes($app)

This is a required method which should generate a list of routes based on the
contents of the object. Each route should be a hashref with these keys:

=over 4

=item path

Path specification for the route.

=item target

Coderef to call to handle the request.

=item defaults

Extra values which will be included in the resulting match.

=item validations

Validation rules for variable path components. See L<Path::Router> for more
information.

=back

=method parse_action_spec($action_spec)

Required class method which should take the actual action specification
provided in the user's router description and return either a C<route_spec>
that can be understood by L<OX::Application::Role::RouteBuilder> or undef (if the action spec wasn't of the form that could be understood by this class).

=cut

requires 'compile_routes', 'parse_action_spec';

=attr path

The path that this route is for. Required.

=cut

has path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=attr route_spec

The C<route_spec> that describes how this path should be routed. See
L<OX::Application::Role::RouteBuilder>. Required.

=cut

has route_spec => (
    is       => 'ro',
    required => 1,
);

=attr params

The C<defaults> and C<validations> for this path. See L<Path::Router> for more
information. Required.

=cut

has params => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

=method extract_defaults_and_validations

Helper method which sorts the C<params> into C<defaults> and C<validations>.

=cut

sub extract_defaults_and_validations {
    my $self = shift;
    my ($params) = @_;

    my ($defaults, $validations) = ({}, {});

    for my $key (keys %$params) {
        if (ref $params->{$key}) {
            $validations->{$key} = $params->{$key}->{'isa'};
        }
        else {
            $defaults->{$key} = $params->{$key};
        }
    }

    return ($defaults, $validations);
}

1;
