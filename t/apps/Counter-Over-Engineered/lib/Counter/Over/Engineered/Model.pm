package Counter::Over::Engineered::Model;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'count' => (
    traits  => [ 'Counter' ],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_counter   => 'inc',
        dec_counter   => 'dec',
        reset_counter => 'reset',
        set_counter   => 'set'
    }
);

no Moose; 1;

__END__
