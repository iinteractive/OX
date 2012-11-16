package OX::RouteBuilder::ControllerAction;
use Moose;
use namespace::autoclean;
# ABSTRACT: OX::RouteBuilder which routes to an action method in a controller class

with 'OX::RouteBuilder';

=head1 SYNOPSIS

  package MyApp;
  use OX;

  has controller => (
      is  => 'ro',
      isa => 'MyApp::Controller',
  );

  router as {
      route '/' => 'controller.index';
  };

=head1 DESCRIPTION

This is an L<OX::RouteBuilder> which routes to action methods on a controller
class. The C<action_spec> should be a string in the form
C<"$controller.$action">, where C<$controller> is the name of a service which
provides a controller instance, and C<$action> is the name of a method on that
class.

C<controller> and C<action> will also be automatically added as defaults for
the route, as well as C<name> (which will be set to C<"$controller.$action">.

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
        my $c = $match->{controller};
        my $a = $match->{action};

        my $s = $app->fetch($c);
        return [
            500,
            [],
            [blessed($app) . " has no service $c"]
        ] unless $s;

        my $component = $s->get;

        return $component->$a(@_)
            if $component;

        return [
            500,
            [],
            ["Component $component has no action $a"]
        ];
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
    return unless $action_spec =~ /^(\w+)\.(\w+)$/;

    return {
        controller => $1,
        action     => $2,
        name       => $action_spec,
    };
}

__PACKAGE__->meta->make_immutable;

=pod

=for Pod::Coverage
  compile_routes
  parse_action_spec

=cut

1;
