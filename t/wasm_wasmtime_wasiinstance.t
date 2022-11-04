use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::WasiConfig;
use Wasm::Wasmtime::WasiInstance;

skip_all '0.27.0 and earlier only' unless Wasm::Wasmtime::FFI::_ver eq '0.27.0';

is(
  Wasm::Wasmtime::WasiInstance->new(Wasm::Wasmtime::Store->new, "wasi_snapshot_preview1"),
  object {
    call [ isa => 'Wasm::Wasmtime::WasiInstance' ] => T();
  },
  'explicit: store',
);

is(
  Wasm::Wasmtime::WasiInstance->new(Wasm::Wasmtime::Store->new, "wasi_snapshot_preview1", Wasm::Wasmtime::WasiConfig->new),
  object {
    call [ isa => 'Wasm::Wasmtime::WasiInstance' ] => T();
  },
  'explicit: store + config',
);

done_testing;
