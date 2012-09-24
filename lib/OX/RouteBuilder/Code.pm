package OX::RouteBuilder::Code;
use Moose;
use namespace::autoclean;
# ABSTRACT: OX::RouteBuilder which routes to a coderef

with 'OX::RouteBuilder';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub compile_routes {
    my $self = shift;

    my ($defaults, $validations) = $self->extract_defaults_and_validations($self->params);

    return {
        path        => $self->path,
        defaults    => $defaults,
        target      => $self->route_spec,
        validations => $validations,
    };
}

sub parse_action_spec {
    my $class = shift;
    my ($action_spec) = @_;

    return unless ref($action_spec) eq 'CODE';
    return $action_spec;
}

__PACKAGE__->meta->make_immutable;

=pod

=for Pod::Coverage
  compile_routes
  parse_action_spec

=cut

1;
