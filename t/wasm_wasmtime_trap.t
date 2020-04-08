use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Trap;

is(
  Wasm::Wasmtime::Trap->new(Wasm::Wasmtime::Store->new, "foo\0"),
  object {
    call [isa => 'Wasm::Wasmtime::Trap'] => T();
    call message => 'foo';
  },
);

done_testing;
