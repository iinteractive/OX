package OX::Application::Role::Request;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: application role to allow the use of request and response objects

use Class::Load 'load_class';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub BUILD { }
before BUILD => sub {
    my $self = shift;

    load_class($self->request_class);
};

=method request_class

=cut

sub request_class { 'OX::Request' }

=method new_request

=cut

sub new_request {
    my $self = shift;
    my ($env) = @_;

    return $self->request_class->new(env => $env);
}

=method handle_response

=cut

sub handle_response {
    my $self = shift;
    my ($res, $req) = @_;

    if (!ref($res)) {
        $res = $req->new_response([
            200, [ 'Content-Type' => 'text/html' ], [ $res ]
        ]);
    }
    elsif (!blessed($res) || !$res->can('finalize')) {
        $res = $req->new_response($res);
    }

    return $res->finalize;
}

=pod

=for Pod::Coverage
  BUILD

=cut

1;
