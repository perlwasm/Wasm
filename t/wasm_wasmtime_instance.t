use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Instance;

is(
  Wasm::Wasmtime::Instance->new(Wasm::Wasmtime::Module->new(wat => '(module)')),
  object {
    call [ isa => 'Wasm::Wasmtime::Instance' ] => T();
  },
  'created instance instance'
);

done_testing;
