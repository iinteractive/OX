package OX::View::TT;
use Moose;
use MooseX::Types::Path::Class;

use Template;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'template_root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

has 'template_config' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has 'tt' => (
    is      => 'ro',
    isa     => 'Template',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Template->new(
            INCLUDE_PATH => $self->template_root,
            %{ $self->template_config }
        )
    }
);

sub normalize_web_base {
    my ($self, $r) = @_;
    my $base = $r->script_name;
    $base = '/' . $base unless $base =~ /^\//;
    $base = $base . '/' unless $base =~ /\/$/;
    $base;
}

sub build_template_params {
    my ($self, $r, $params) = @_;
    my $BASE = $self->normalize_web_base( $r );
    return +{
        r           => $r,
        base        => $BASE,
        uri_for     => sub { $BASE . $r->router->uri_for( %{ $_[0] } ) },
        %{ $params || {} }
    }
}

sub render {
    my ($self, $r, $template, $params) = @_;
    my $out = '';
    $self->tt->process(
        $template,
        $self->build_template_params( $r, $params ),
        \$out
    ) || confess $self->tt->error;
    $out;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::View::TT - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::View::TT;

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

Copyright 2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
