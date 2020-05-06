use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Global;

is(
  Wasm::Wasmtime::Global->new(
    Wasm::Wasmtime::Store->new,
    Wasm::Wasmtime::GlobalType->new(
      'i32',
      'var',
    ),
    42
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Global' ] => T();
    call type => object {
      call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
    };
    call get => 42;
    call [ set => 99 ] => U();
    call get => 99;

    call is_func   => F();
    call is_global => T();
    call is_table  => F();
    call is_memory => F();
    call kind      => 'global';
  },
);

done_testing;
