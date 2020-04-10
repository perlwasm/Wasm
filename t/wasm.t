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
  package Foo0;
  use Wasm -api => 0, -wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "subtract") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.sub)
      (memory (export "frooble") 2 3)
    )
  };
}

is( Foo0::add(1,2), 3, '1+2=3' );
is( Foo0::subtract(3,2), 1, '3-2=1' );

{
  package Foo1;
  use Wasm -api => 0, -file => 'corpus/wasm/math.wat';
}

is( Foo1::add(1,2), 3, '1+2=3' );
is( Foo1::subtract(3,2), 1, '3-2=1' );

{
  package Foo2;
  use File::Temp qw( tempdir );
  use Path::Tiny qw( path );
  use Wasm -api => 0, -file => do {
    my $wat  = path('corpus/wasm/math.wat');
    my $wasm = path(tempdir( CLEANUP => 1 ))->child('math.wasm');
    require Wasm::Wasmtime::Wat2Wasm;
    $wasm->spew_raw(Wasm::Wasmtime::Wat2Wasm::wat2wasm($wat->slurp_utf8));
    $wasm->stringify;
  };
}

is( Foo2::add(1,2), 3, '1+2=3' );
is( Foo2::subtract(3,2), 1, '3-2=1' );

done_testing;
