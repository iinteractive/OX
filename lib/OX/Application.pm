package OX::Application;
use Moose;

use Bread::Board ();
use Path::Router;
use Path::Class;
use Class::Inspector;

use Plack::App::Path::Router;

use OX::Web::Request;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

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
    default => sub {
        my $self = shift;
        Bread::Board::Container->new( name => $self->name )
    },
);

has 'root' => (
    is      => 'ro',
    isa     => 'Any',
    default => sub {
        my $class = (shift)->meta->name;
        my $root  = file( Class::Inspector->resolved_filename( $class ) );
        # climb out of the lib/ directory
        $root = $root->parent foreach split /\:\:/ => $class;
        $root = $root->parent; # one last time for lib/
        $root;
    },
);

has 'is_setup' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub setup {
    my $self = shift;

    return if $self->is_setup;

    Bread::Board::set_root_container( $self->bread_board );

    Bread::Board::service 'root' => $self->root;

    inner();

    $self->setup_router;
    $self->setup_application;

    $Bread::Board::CC = undef;

    $self->is_setup(1);
}

sub setup_router {
    my $self = shift;
    Bread::Board::service 'Router' => (
        class => 'Path::Router',
        block => sub {
            my $s      = shift;
            my $router = Path::Router->new;
            $self->configure_router( $s, $router ) || $router;
        },
        dependencies => $self->router_dependencies
    );
}

sub router_dependencies { [] }
sub configure_router {
    my ($self, $s, $router) = @_;
    $router;
}

sub setup_application {
    my $self = shift;
    my $deps = $self->application_dependencies;

    if (ref $deps eq 'ARRAY') {
        push @$deps => Bread::Board::depends_on('Router');
    }
    elsif (ref $deps eq 'HASH') {
        $deps->{'Router'} = Bread::Board::depends_on('Router');
    }

    Bread::Board::service 'Application' => (
        block => sub {
            my $s   = shift;
            my $app = Plack::App::Path::Router->new(
                router        => $s->parent->fetch('Router')->get,
                request_class => 'OX::Web::Request',
            );
            $self->configure_application( $s, $app ) || $app;
        },
        dependencies => $deps
    );
}

sub application_dependencies { [] }
sub configure_application {
    my ($self, $s, $app) = @_;
    $app;
}

sub fetch_service {
    my ($self, $service_path, %params) = @_;
    $self->bread_board->fetch( $service_path )->get( %params );
}

sub to_app {
    my $self = shift;
    $self->setup;
    $self->bread_board->fetch('Application')->get
}

# ...

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
