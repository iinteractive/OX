package OX::RouteBuilder;
use Moose::Role;
use namespace::autoclean;

requires 'compile_routes', 'parse_action_spec';

has path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has route_spec => (
    is       => 'ro',
    required => 1,
);

has params => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

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
