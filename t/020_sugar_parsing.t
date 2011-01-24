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

    config template_root1 => 'foo';
    config template_root2 => sub { 'foo' };
    config template_root3 => sub { shift->param('template_root') }, (
        template_root => depends_on('/Config/template_root1'),
    );
    config template_root4 => sub { shift->param('template_root') }, {
        lifecycle    => 'Singleton',
        dependencies => {
            template_root => depends_on('/Config/template_root2'),
        },
    };
    config template_root5 => {
        block        => sub { shift->param('template_root') },
        lifecycle    => 'Singleton',
        dependencies => {
            template_root => depends_on('/Config/template_root3'),
        },
    };
    config template_root6 => {
        value => 'foo',
    };
    config {
        name      => 'template_root7',
        value     => 'foo',
        lifecycle => 'Singleton',
    };
    config view_as_config => {
        class => 'View',
        dependencies => {
            template_root => depends_on('/Config/template_root4'),
        },
    };

    component View1 => 'View';
    component View2 => 'View' => (
        template_root => depends_on('/Config/template_root1'),
    );
    component View3 => 'View' => {
        lifecycle    => 'Singleton',
        dependencies => {
            template_root => depends_on('/Config/template_root2'),
        },
    };
    component View4 => sub { View->new(template_root => '/') };
    component View5 => sub {
        View->new(template_root => shift->param('template_root'))
    }, (template_root => depends_on('/Config/template_root3'));
    component View6 => sub {
        View->new(template_root => shift->param('template_root'))
    }, {
        lifecycle    => 'Singleton',
        dependencies => {
            template_root => depends_on('/Config/template_root4'),
        },
    };
    component View7 => {
        class        => 'View',
        lifecycle    => 'Singleton',
        dependencies => {
            template_root => depends_on('/Config/template_root5'),
        },
    };
    component View8 => {
        block        => sub {
            View->new(template_root => shift->param('template_root'))
        },
        lifecycle    => 'Singleton',
        dependencies => {
            template_root => depends_on('/Config/template_root6'),
        },
    };
    component {
        name         => 'View9',
        class        => 'View',
        dependencies => {
            template_root => depends_on('/Config/template_root7'),
        },
    };
    component {
        name  => 'View10',
        block => sub { View->new(template_root => '/') },
    };
}

isa_ok('Foo', 'OX::Application');
my $foo = Foo->new;

{
    my $service = $foo->fetch('/Config/template_root1');
    isa_ok($service, 'Bread::Board::Literal');
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('/Config/template_root2');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 0, "no dependencies");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('/Config/template_root3');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root1', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('/Config/template_root4');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root2', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('/Config/template_root5');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root3', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('/Config/template_root6');
    isa_ok($service, 'Bread::Board::Literal');
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('/Config/template_root7');
    isa_ok($service, 'Bread::Board::Literal');
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    is($service->get, 'foo', "got the right value");
}

{
    my $service = $foo->fetch('/Config/view_as_config');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root4', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View1');
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
    my $service = $foo->fetch('/Component/View2');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root1', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View3');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root2', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View4');
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
    my $service = $foo->fetch('/Component/View5');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root3', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View6');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root4', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View7');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root5', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View8');
    isa_ok($service, 'Bread::Board::BlockInjection');
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root6', "correct dependency");
    ok($service->does('Bread::Board::LifeCycle::Singleton'),
       "singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View9');
    isa_ok($service, 'Bread::Board::ConstructorInjection');
    is($service->class, 'View', "correct class");
    my $deps = $service->dependencies;
    is(scalar(keys %$deps), 1, "only one dependency");
    my $dep = $service->get_dependency('template_root');
    isa_ok($dep, 'Bread::Board::Dependency');
    is($dep->service_path, '/Config/template_root7', "correct dependency");
    ok(!$service->does('Bread::Board::LifeCycle::Singleton'),
       "not a singleton");
    my $view = $service->get;
    isa_ok($view, 'View');
    is($view->template_root, 'foo', "correct attr value");
}

{
    my $service = $foo->fetch('/Component/View10');
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
