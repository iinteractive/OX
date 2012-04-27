use OX;

my $counter = 0;

router as {
    route '/'         => sub { $counter         };
    route '/inc'      => sub { ++$counter       };
    route '/dec'      => sub { --$counter       };
    route '/reset'    => sub { $counter = 0     };
    route '/set/:num' => sub { $counter = $_[1] }, (
        num => { isa => 'Int' },
    );
};

__PACKAGE__->new->to_app;
