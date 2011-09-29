package Bread::Board::LifeCycle::Request;
use Moose::Role;
use namespace::autoclean;

# just behaves like a singleton - ::Request instances
# will get flushed after the response is sent
with 'Bread::Board::LifeCycle::Singleton';

1;
