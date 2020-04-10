use Test2::V0 -no_srand => 1;
use Wasm;

try_ok  { Wasm->import( -api => 0 );    }                                                   'works with -api => 0 ';
is(dies { Wasm->import( -api => 2 );    }, match qr/Currently only -api => 0 is supported/, 'dies with non 0 api level');
is(dies { Wasm->import( -foo => 'bar'); }, match qr/You MUST specify an api level as the first option/,
                                                                                            'bad key ');
is(dies { Wasm->import( -api => 0, -api => 0 ) },
                                           match qr/Specified -api more than once/,         'api more than once');
try_ok  { Wasm->import( -api => 0, -wat => '(module)' ) }                                   'empty module';

{
  package Foo;
  use Wasm -api => 0, -wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "sub") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.sub)
      (memory (export "frooble") 2 3)
    )
  };
}

is( Foo::add(1,2), 3, '1+2=3' );
is( Foo::sub(3,2), 1, '3-2=1' );

done_testing;


