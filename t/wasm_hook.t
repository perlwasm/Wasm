use Test2::V0 -no_srand => 1;
use Wasm::Hook;
use lib 'corpus/lib';
use Foo::Bar::Baz::Math;

is(Foo::Bar::Baz::Math::add(1,2), 3);

Wasm::Hook->unimport;

is(
  dies { require Foo::Bar::Baz::Math2 },
  match qr/Can't locate Foo\/Bar\/Baz\/Math2\.pm/,
);

done_testing;


