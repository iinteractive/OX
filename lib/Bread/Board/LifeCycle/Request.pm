package Bread::Board::LifeCycle::Request;
use Moose::Role;

# just behaves like a singleton - ::Request instances
# will get flushed after the response is sent
with 'Bread::Board::LifeCycle::Singleton';

no Moose::Role;

1;
