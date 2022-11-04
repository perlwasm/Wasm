use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Context;

skip_all '0.28.0 and better only' unless Wasm::Wasmtime::FFI::_ver ne '0.27.0';

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
