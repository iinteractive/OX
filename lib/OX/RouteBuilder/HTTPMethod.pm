package OX::RouteBuilder::HTTPMethod;
use Moose;
use namespace::autoclean;
# ABSTRACT: OX::RouteBuilder which routes to a method in a controller based on the HTTP method

with 'OX::RouteBuilder';

=head1 SYNOPSIS

  package MyApp;
  use OX;

  has controller => (
      is  => 'ro',
      isa => 'MyApp::Controller',
  );

  router as {
      route '/' => 'controller';
  };

=head1 DESCRIPTION

This is an L<OX::RouteBuilder> which allows to a controller class based on the
HTTP method used in the request. The C<action_spec> should be a string
corresponding to a service which provides a controller instance. When a request
is made for the given path, it will look in that class for a method which
corresponds to the lowercased version of the HTTP method used in the request
(for instance, C<get>, C<post>, etc). If no method is found, it will fall back
to looking for a method named C<any>. If that isn't found either, an error will
be raised.

=cut

sub compile_routes {
    my $self = shift;
    my ($app) = @_;

    my $spec = $self->route_spec;
    my $params = $self->params;

    my ($defaults, $validations) = $self->extract_defaults_and_validations($params);
    $defaults = { %$spec, %$defaults };

    my $target = sub {
        my ($req) = @_;

        my $match = $req->mapping;
        my $a = $match->{action};

        my $s = $app->fetch($a);
        return [
            500,
            [],
            [blessed($app) . " has no service $a"]
        ] unless $s;

        my $component = $s->get;
        my $method = lc($req->method);

        if ($component->can($method)) {
            return $component->$method(@_);
        }
        elsif ($component->can('any')) {
            return $component->any(@_);
        }
        else {
            return [
                500,
                [],
                ["Component $component has no method $method"]
            ];
        }
    };

    return {
        path        => $self->path,
        defaults    => $defaults,
        target      => $target,
        validations => $validations,
    };
}

sub parse_action_spec {
    my $class = shift;
    my ($action_spec) = @_;

    return if ref($action_spec);
    return unless $action_spec =~ /^(\w+)$/;

    return {
        action => $1,
        name   => $action_spec,
    };
}

__PACKAGE__->meta->make_immutable;

=pod

=for Pod::Coverage
  compile_routes
  parse_action_spec

=cut

1;
