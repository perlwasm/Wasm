use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Func;

is(
  wasm_func_ok( add => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
    )
  }),
  object {
    call [ call => 1, 2 ] => 3;
    call [ call => 3, 4 ] => 7;
  },
  'call add',
);

done_testing;
