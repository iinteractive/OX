#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package View;
    use Moose;

    has template_root => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );
}

{
    package Foo;
    use OX;

    has template_root1 => (
        is    => 'ro',
        isa   => 'Str',
        value => 'foo',
    );

    has template_root2 => (
        is    => 'ro',
        isa   => 'Str',
        block => sub { 'foo' },
    );

    has template_root3 => (
        is           => 'ro',
        isa          => 'Str',
        block        => sub { shift->param('template_root') },
        dependencies => {
            template_root => 'template_root1',
        },
    );

    has template_root4 => (
        is           => 'ro',
        isa          => 'Str',
        block        => sub { shift->param('template_root') },
        dependencies => {
            template_root => 'template_root2',
        },
        lifecycle    => 'Singleton',
    );

    has template_root5 => (
        is           => 'ro',
        isa          => 'Str',
        block        => sub { shift->param('template_root') },
        dependencies => {
            template_root => 'template_root3',
        },
        lifecycle    => 'Singleton',
    );

    has template_root6 => (
        is    => 'ro',
        isa   => 'Str',
        value => 'foo',
    );

    has template_root7 => (
        is        => 'ro',
        isa       => 'Str',
        value     => 'foo',
        lifecycle => 'Singleton',
    );

    has view_as_config => (
        is           => 'ro',
        isa          => 'View',
        dependencies => {
            template_root => 'template_root4',
        },
    );

    has View1 => (
        is  => 'ro',
        isa => 'View',
    );

    has View2 => (
        is           => 'ro',
        isa          => 'View',
        dependencies => {
            template_root => 'template_root1',
        },
    );

    has View3 => (
        is           => 'ro',
        isa          => 'View',
        dependencies => {
            template_root => 'template_root2',
        },
        lifecycle    => 'Singleton',
    );

    has View4 => (
        is    => 'ro',
        isa   => 'View',
        block => sub { View->new(template_root => '/') },
    );

    has View5 => (
        is           => 'ro',
        isa          => 'View',
        block        => sub {
            View->new(template_root => shift->param('template_root'))
        },
        dependencies => {
            template_root => 'template_root3',
        },
    );

    has View6 => (
        is           => 'ro',
        isa          => 'View',
        block        => sub {
            View->new(template_root => shift->param('template_root'))
        },
        dependencies => {
            template_root => 'template_root4',
        },
        lifecycle    => 'Singleton',
    );

    has View7 => (
        is           => 'ro',
        isa          => 'View',
        dependencies => {
            template_root => 'template_root5',
        },
        lifecycle    => 'Singleton',
    );

    has View8 => (
        is           => 'ro',
        isa          => 'View',
        block        => sub {
            View->new(template_root => shift->param('template_root'))
        },
        dependencies => {
            template_root => 'template_root6',
        },
        lifecycle    => 'Singleton',
    );

    has View9 => (
        is           => 'ro',
        isa          => 'View',
        dependencies => {
            template_root => 'template_root7',
        },
    );

    has View10 => (
        is    => 'ro',
        isa   => 'View',
        block => sub { View->new(template_root => '/') },
    );
}

isa_ok('Foo', 'OX::Application');
my $foo = Foo->new;

{
    my $service = $foo->fetch('template_root1');
    isa_ok($service, 'Bread::Board::Literal');
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('template_root2');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 0, "no dependencies");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('template_root3');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root1', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('template_root4');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root2', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('template_root5');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root3', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('template_root6');
    isa_ok($service, 'Bread::Board::Literal');
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('template_root7');
    isa_ok($service, 'Bread::Board::Literal');
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('view_as_config');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root4', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View1');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 0, "no dependencies");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    like(exception { $service->get }, qr/template_root.*required/,
         "can't instantiate without deps being fulfilled");
}

{
    my $service = $foo->fetch('View2');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root1', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View3');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root2', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View4');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 0, "no dependencies");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, '/', "correct attr value");
}

{
    my $service = $foo->fetch('View5');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root3', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View6');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root4', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View7');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root5', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View8');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root6', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View9');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, 'template_root7', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('View10');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 0, "no dependencies");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, '/', "correct attr value");
}

done_testing;
