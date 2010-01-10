package OX::Application;
use Moose;
use MooseX::NonMoose;

use Bread::Board ();

use Path::Class;
use Class::Inspector;

use Path::Router;
use Plack::App::Path::Router;

use OX::Web::Request;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Plack::Component';

has '_app' => ( is => 'rw', isa => 'CodeRef' );

has 'name' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { (shift)->meta->name },
);

has 'bread_board' => (
    is      => 'ro',
    isa     => 'Bread::Board::Container',
    lazy    => 1,
    builder => 'setup_bread_board'
);

sub setup_bread_board {
    my $self = shift;

    my $bb = Bread::Board::Container->new( name => $self->name );

    Bread::Board::set_root_container( $bb );

    # XXX - this might not be a good idea - SL
    Bread::Board::service 'app_root' => do {
        my $class = $self->meta->name;
        my $root  = file( Class::Inspector->resolved_filename( $class ) );
        # climb out of the lib/ directory
        $root = $root->parent foreach split /\:\:/ => $class;
        $root = $root->parent; # one last time for lib/
        $root;
    };

    inner();

    $self->setup_router;

    $Bread::Board::CC = undef;

    $bb;
}

# ... Router handling/setup

sub setup_router {
    my $self = shift;
    Bread::Board::service 'Router' => (
        class => 'Path::Router',
        block => sub {
            my $s      = shift;
            my $router = Path::Router->new;
            $self->configure_router( $s, $router );
            $router;
        },
        dependencies => $self->router_dependencies
    );
}

sub router_dependencies { [] }
sub configure_router {
    #my ($self, $s, $router) = @_;
}

# ... Public Utils

sub fetch_service {
    my ($self, $service_path, %params) = @_;
    $self->bread_board->fetch( $service_path )->get( %params );
}

# ... Plack::Component API

sub prepare_app {
    my $self = shift;
    $self->_app(
        Plack::App::Path::Router->new(
            router        => $self->fetch_service('Router'),
            request_class => 'OX::Web::Request',
        )->to_app
    );
}

sub call {
    my ($self, $env) = @_;
    $self->_app->( $env );
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
