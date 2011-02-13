package OX::Application::RouteBuilder::ControllerAction;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

with 'OX::Application::RouteBuilder';

sub compile_routes {
    my $self = shift;

    my $spec = $self->route_spec;
    my $params = $self->params;

    my ($defaults, $validations) = $self->extract_defaults_and_validations($params);
    $defaults = { %$spec, %$defaults };

    my $s = $self->service;

    return [
        $self->path,
        defaults    => $defaults,
        target      => sub {
            my ($req) = @_;

            my %match = %{ $req->env->{'plack.router.match'}->mapping };
            my $c = $match{controller};
            my $a = $match{action};

            my $component = $s->get_dependency($c)->get;

            if ($component->can($a)) {
                return $component->$a(@_);
            }
            else {
                return [
                    500,
                    [],
                    ["Component $component has no action $a"]
                ];
            }
        },
        validations => $validations,
    ];
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::Application::RouteBuilder::ControllerAction - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::Application::RouteBuilder::ControllerAction;

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
