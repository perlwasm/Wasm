use 5.008004;
use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use Wasm::Wasmtime::Memory;
use Wasm::Wasmtime::Store;

is(
  Wasm::Wasmtime::Memory->new(
    Wasm::Wasmtime::Store->new,
    Wasm::Wasmtime::MemoryType->new([1,2]),
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
  },
  'standalone',
);

is(
  Wasm::Wasmtime::Memory->new(
    Wasm::Wasmtime::Store->new,
    [1,2],
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
  },
  'standalone (ii)',
);

is(
  Wasm::Wasmtime::Memory->new(
    Wasm::Wasmtime::Store->new,
    [2, 6],
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
    call type => object {
      call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
    };
    call data => match qr/^[0-9]+$/;
    call data_size => match qr/^[0-9]+$/;
    call size => 2;
    call [ grow => 3] => T();
    call size => 5;
    call is_func   => F();
    call is_global => F();
    call is_table  => F();
    call is_memory => T();
    call kind      => 'memory';
  },
  'call methods'
);

done_testing;
