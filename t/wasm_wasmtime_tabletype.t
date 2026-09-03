use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::TableType;

is(
  Wasm::Wasmtime::TableType->new('funcref',[3,4]),
  object {
    call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
    call element => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'funcref';
    };
    call limits => [3,4];
    call is_functype   => F();
    call is_globaltype => F();
    call is_tabletype  => T();
    call is_memorytype => F();
    call kind          => 'tabletype';

    call to_string => '3 4 funcref';
  },
  'funcref',
);

is(
  Wasm::Wasmtime::TableType->new('funcref',[9,undef]),
  object {
    call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
    call element => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'funcref';
    };
    call limits => [9,0xffffffff];
    call to_string => '9 funcref';
  },
  'funcref no max',
);

is(
  Wasm::Wasmtime::TableType->new(Wasm::Wasmtime::ValType->new('externref'),[1,6]),
  object {
    call [ isa => 'Wasm::Wasmtime::TableType' ] => T();
    call element => object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => 'anyref';
    };
    call limits => [1,6];
    call to_string => '1 6 anyref';
  },
  'externref',
);

done_testing;
