package PomodorOX;
use OX;

use Lingua::EN::Numbers qw/ num2en_ordinal /;

my $goal   = 12;
my $done   = 0;
my $state  = 'initial';

router as {
  route '/' => sub {
    my $ord = num2en_ordinal( $done+1 );

    my $label = ( $state eq 'break' or $state eq 'initial') ?
      "Start $ord pomodoro" : "Finish $ord pomodoro and take a break";

    if ( $state eq 'pomo' ) {
      $state = 'break';
      $done++;
    }
    else { $state = 'pomo' }

    return <<EOHTML;
<p>POMODOROS DONE / PLANNED: $done / $goal
<input type="button" value="$label" onclick="window.location = '/';" /></p>
EOHTML
  };
};
