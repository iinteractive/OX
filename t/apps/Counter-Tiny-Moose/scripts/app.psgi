use OX;

has counter => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_counter   => 'inc',
        dec_counter   => 'dec',
        reset_counter => 'reset'
    },
);

has '+middleware' => (
    default => sub {
        my $self = shift;
        return [
            sub {
                my $app = shift;
                return sub {
                    my $env = shift;
                    $env->{'ox.app'} = $self;
                    $app->($env);
                };
            }
        ]
    },
);

router as {
    route '/'         => sub { $_[0]->env->{'ox.app'}->counter        };
    route '/inc'      => sub { $_[0]->env->{'ox.app'}->inc_counter    };
    route '/dec'      => sub { $_[0]->env->{'ox.app'}->dec_counter    };
    route '/reset'    => sub { $_[0]->env->{'ox.app'}->reset_counter  };
    route '/set/:num' => sub { $_[0]->env->{'ox.app'}->counter($_[1]) }, (
        num => { isa => 'Int' },
    );
};

xo;
