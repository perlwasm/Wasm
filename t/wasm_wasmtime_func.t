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

is(
  wasm_func_ok( round_trip_many => q{
    (module
  (func $round_trip_many
    (export "round_trip_many")
    (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)
    (result i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)

    local.get 0
    local.get 1
    local.get 2
    local.get 3
    local.get 4
    local.get 5
    local.get 6
    local.get 7
    local.get 8
    local.get 9)
    )
  }),
  object {
    call_list [ call => 0,1,2,3,4,5,6,7,8,9 ] => [0,1,2,3,4,5,6,7,8,9];
  },
  'call round_trip_many',
);

done_testing;
