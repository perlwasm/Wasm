use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::WasiConfig;
use Wasm::Wasmtime::WasiInstance;

is(
  Wasm::Wasmtime::WasiInstance->new("foo"),
  object {
    call [ isa => 'Wasm::Wasmtime::WasiInstance' ] => T();
  },
  'defaults',
);

is(
  Wasm::Wasmtime::WasiInstance->new(Wasm::Wasmtime::Store->new, "foo"),
  object {
    call [ isa => 'Wasm::Wasmtime::WasiInstance' ] => T();
  },
  'explicit: store',
);

is(
  Wasm::Wasmtime::WasiInstance->new("foo", Wasm::Wasmtime::WasiConfig->new),
  object {
    call [ isa => 'Wasm::Wasmtime::WasiInstance' ] => T();
  },
  'explicit: config',
);

is(
  Wasm::Wasmtime::WasiInstance->new(Wasm::Wasmtime::Store->new, "foo", Wasm::Wasmtime::WasiConfig->new),
  object {
    call [ isa => 'Wasm::Wasmtime::WasiInstance' ] => T();
  },
  'explicit: store + config',
);

done_testing;
