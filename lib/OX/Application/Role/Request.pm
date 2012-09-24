package OX::Application::Role::Request;
use Moose::Role;
use namespace::autoclean;

use Class::Load 'load_class';

sub BUILD { }
before BUILD => sub {
    my $self = shift;

    load_class($self->request_class);
};

sub request_class { 'OX::Request' }

sub new_request {
    my $self = shift;
    my ($env) = @_;

    return $self->request_class->new(env => $env);
}

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

1;
