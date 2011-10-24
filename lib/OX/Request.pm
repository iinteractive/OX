package OX::Request;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

use OX::Response;

extends 'Plack::Request';

sub BUILDARGS {
    return {};
}

sub _router { (shift)->env->{'ox.router'} }

sub mapping {
    my $self = shift;
    my $match = $self->env->{'plack.router.match'};
    return unless $match;
    return %{ $match->mapping };
}

sub uri_for {
    my ($self, $route) = @_;
    my $uri_base = $self->script_name || '/';
    $uri_base .= '/' unless $uri_base =~ m+/$+;
    my $path_info = $self->_router->uri_for( %$route );
    confess "No URI found for route"
        unless defined($path_info);
    return $uri_base . $path_info;
}

sub new_response {
    my $self = shift;
    OX::Response->new( @_ );
}

around ['query_parameters', 'body_parameters'] => sub {
    my $orig = shift;
    my $self = shift;

    my $ret = $self->$orig(@_);

    my $mixed = $ret->mixed;
    for my $key (keys %$mixed) {
        my $val = $mixed->{$key};
        if (ref $val eq 'ARRAY') {
            $val = [ map { $self->decode($_) } @$val ];
        }
        else {
            $val = $self->decode($val);
        }
        $mixed->{$key} = $val;
    }

    return Hash::MultiValue->from_mixed($mixed);
};

around content => sub {
    my $orig = shift;
    my $self = shift;

    my $content = $self->$orig(@_);
    return $self->decode($content);
};

sub decode {
    my $self = shift;
    my ($content) = @_;
    utf8::decode($content);
    return $content;
}

sub encode {
    my $self = shift;
    my ($content) = @_;
    utf8::encode($content);
    return $content;
}

__PACKAGE__->meta->make_immutable;

1;
