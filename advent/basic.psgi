package MyOXsomeApp;
use OX;

router as {
  route '/' => sub { "hello world!" };

  wrap 'Plack::Middleware::Auth::Basic' => (
    authenticator => literal sub {
      my( $user , $pass ) = @_;
      return $user eq 's00per' and $pass eq 's3kr1t';
    },
    realm => literal "my awesome app!",
  );
};
