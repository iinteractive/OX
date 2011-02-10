package OX::Application;
use Moose;
use Bread::Board;

use OX::Router;
use Plack::App::Path::Router::PSGI;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Bread::Board::Container';

has '+name' => ( lazy => 1, default => sub { (shift)->meta->name } );

has '_app' => ( is => 'rw', isa => 'CodeRef' );

# can override this to Path::Router to deal with PSGI coderefs directly
has 'router_class' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'OX::Router',
);

sub BUILD {
    my $self = shift;
    container $self => as {

        container 'Router' => as {

            service 'router' => (
                class => $self->router_class,
                block => sub {
                    my $s      = shift;
                    my $router = $self->router_class->new;
                    $self->configure_router( $s, $router );
                    $router;
                },
                dependencies => $self->router_dependencies
            );

        };

    };
}

sub router_dependencies { [] }
sub configure_router { }

# ... Plack::Component API

sub prepare_app {
    my $self = shift;
    $self->_app(
        Plack::App::Path::Router::PSGI->new(
            router => $self->resolve( service => 'Router/router' ),
        )->to_app
    );
}

sub call {
    my ($self, $env) = @_;
    $self->_app->( $env );
}

sub to_app {
    my $self = shift;
    $self->prepare_app;
    return sub { $self->call( @_ ) };
}

# ... Private Utils

sub _dump_bread_board {
    require Bread::Board::Dumper;
    Bread::Board::Dumper->new->dump( (shift)->bread_board );
}

no Moose; no Bread::Board; 1;

__END__

=pod

=head1 NAME

OX::Application - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::Application;

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
