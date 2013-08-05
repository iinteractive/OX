package OX::Types;
use strict;
use warnings;

use Class::Load 'load_class';
use Moose::Util::TypeConstraints;

class_type('Plack::Middleware');
subtype 'OX::Types::MiddlewareClass',
     as 'Str',
     where { load_class($_); $_->isa('Plack::Middleware') };
subtype 'OX::Types::Middleware',
     as 'CodeRef|OX::Types::MiddlewareClass|Plack::Middleware';

=for Pod::Coverage

=cut

1;
