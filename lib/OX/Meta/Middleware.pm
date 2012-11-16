package OX::Meta::Middleware;
use Moose;
use namespace::autoclean;

has middleware => (
    is       => 'ro',
    isa      => 'OX::Types::Middleware',
    required => 1,
);

has dependencies => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has condition => (
    is  => 'ro',
    isa => 'CodeRef',
);

sub resolve {
    my $self = shift;
    my ($container) = @_;

    my $mw = $self->middleware;
    my $deps = $self->dependencies;

    my %common = (
        name   => '__ANON__',
        parent => $container,
    );
    my $mw_service;
    if (!ref($mw)) {
        $mw_service = Bread::Board::ConstructorInjection->new(
            %common,
            class        => $mw,
            dependencies => $deps,
        );
    }
    elsif (blessed($mw)) {
        $mw_service = Bread::Board::Literal->new(
            %common,
            value => $mw,
        );
    }
    else {
        $mw_service = Bread::Board::BlockInjection->new(
            %common,
            block        => sub {
                my $s = shift;
                return sub {
                    my $app = shift;
                    return $mw->($app, $s);
                };
            },
            dependencies => $deps,
        );
    }

    my $resolved_mw = $mw_service->get;

    if (my $condition = $self->condition) {
        require Plack::Middleware::Conditional;
        my $builder = $resolved_mw;
        $resolved_mw = sub {
            Plack::Middleware::Conditional->new(
                condition => $condition,
                builder   => sub {
                    OX::Util::apply_middleware($_[0], $builder)
                },
            )->wrap($_[0]);
        };
    }

    return $resolved_mw;
}

__PACKAGE__->meta->make_immutable;

=for Pod::Coverage
  resolve

=cut

1;
