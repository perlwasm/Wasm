use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Linker;

is(
  Wasm::Wasmtime::Linker->new(
    Wasm::Wasmtime::Store->new,
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Linker' ] => T();
  },
  'basic object create'
);

done_testing;
