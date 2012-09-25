package Bread::Board::LifeCycle::Request;
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: lifecycle for request-scoped services

=head1 SYNOPSIS

  service Controller => (
      class     => 'MyApp::Controller',
      lifecycle => 'Request',
  );

or, with L<Bread::Board::Declare>:

  has controller => (
      is        => 'ro',
      isa       => 'MyApp::Controller',
      lifecycle => 'Request',
  );

=head1 DESCRIPTION

This implements a request-scoped lifecycle for L<Bread::Board>. Services with
this lifecycle will persist throughout a single request as though they were a
L<Singleton|Bread::Board::Lifecycle::Singleton>, but they will be cleared when
the request is finished.

=cut

# just behaves like a singleton - ::Request instances
# will get flushed after the response is sent
with 'Bread::Board::LifeCycle::Singleton';

1;
