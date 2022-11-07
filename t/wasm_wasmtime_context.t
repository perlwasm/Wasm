use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Context;

is(
  Wasm::Wasmtime::Store->new,
  object {
    call context => object {
      call [ isa => 'Wasm::Wasmtime::Context' ] => T();
      call gc => U();
    };
  },
  'default'
);

done_testing;
