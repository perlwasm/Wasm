use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

isa_ok(
  Wasm::Wasmtime::Engine->new,
  'Wasm::Wasmtime::Engine',
);

isa_ok(
  Wasm::Wasmtime::Engine->new(Wasm::Wasmtime::Config->new),
  'Wasm::Wasmtime::Engine',
);

done_testing;


