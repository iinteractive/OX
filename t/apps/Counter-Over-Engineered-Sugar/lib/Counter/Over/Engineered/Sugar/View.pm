package Counter::Over::Engineered::Sugar::View;
use Moose;

use MooseX::Types::Path::Class;
use Template;

has 'template_root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

has 'tt' => (
    is      => 'ro',
    isa     => 'Template',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Template->new(INCLUDE_PATH => $self->template_root)
    },
);

sub render {
    my ($self, $r, $template, $params) = @_;
    my $out;
    $self->tt->process(
        $template,
        {
            uri_for => sub { $r->uri_for( $_[0] ) },
            %{ $params || {} },
        },
        \$out
    );
    return $out;
}

no Moose; 1;

__END__
