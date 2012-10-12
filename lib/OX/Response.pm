package OX::Response;
use Moose;
# ABSTRACT: response object for OX

extends 'Web::Response';

=head1 SYNOPSIS

  use OX::Request;

  my $req = OX::Request->new(env => $env);
  my $response = $req->new_response;

=head1 DESCRIPTION

This class is a simple subclass of L<Web::Response>. Right now, it doesn't add
any additional functionality, but it does provide a place to add new features
in later.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
