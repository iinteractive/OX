package OX::RouteBuilder;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: abstract role for classes that turn configuration into a route

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=method compile_routes

=method parse_action_spec

=cut

requires 'compile_routes', 'parse_action_spec';

=attr path

=cut

has path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=attr route_spec

=cut

has route_spec => (
    is       => 'ro',
    required => 1,
);

=attr params

=cut

has params => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

=method extract_defaults_and_validations

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
