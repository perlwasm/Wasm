use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::GlobalType;

is(
  Wasm::Wasmtime::GlobalType->new('i32','const'),
  object {
    call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    }
  },
  'i32,const',
);

is(
  Wasm::Wasmtime::GlobalType->new('i64','var'),
  object {
    call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    }
  },
  'i64,var',
);

is(
  Wasm::Wasmtime::GlobalType->new(Wasm::Wasmtime::ValType->new('f32'),'var'),
  object {
    call [ isa => 'Wasm::Wasmtime::GlobalType' ] => T();
    call as_externtype => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    }
  },
  '(i64),var',
);

done_testing;
