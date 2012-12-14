package MyOXsomeApp;
use OX;

use HTTP::Throwable::Factory qw/ http_throw /;

router as {
  route '/' => sub { "hello world!" };

  route '/admin' => sub { 
    my( $request ) = @_;

    my $user;
    unless( $user = $request->session->{user_id} ) { 
      $request->session->{redir_to} = '/admin';
      http_throw( Found => { location => '/login' } );
    }
    return "admin section!<br/>hello $user!";
  };

  wrap 'Plack::Middleware::Session' =>( store => literal( 'File' ));

  wrap 'Plack::Middleware::Auth::Form' => (
    authenticator => literal( sub {
        my( $user , $pass ) = @_;
        return $user eq 's00per' and $pass eq 's3kr1t';
    }),
  );
};
