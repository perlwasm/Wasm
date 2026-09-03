use 5.008004;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::MemoryType;

is(
  wasm_module_ok(q{
    (module
      (memory (export "frooble") 2 6)
    )
  }),
  object {
    call exports => object {
      call frooble => object {
        call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
        call limits => [2,6];
        call minimum => 2;
        call maximum => 6;
        call is64      => F();
        call is_shared => F();
        call page_size      => 65536;
        call page_size_log2 => 16;
        call is_functype   => F();
        call is_globaltype => F();
        call is_tabletype  => F();
        call is_memorytype => T();
        call kind          => 'memorytype';
        call to_string     => '2 6';
      };
    };
  },
  'memorytype class basics',
);

is(
  Wasm::Wasmtime::MemoryType->new([2,3]),
  object {
    call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
    call limits    => [2,3];
    call minimum   => 2;
    call maximum   => 3;
    call is64      => F();
    call is_shared => F();
    call to_string => '2 3';
  },
  'standalone',
);

is(
  Wasm::Wasmtime::MemoryType->new([1]),
  object {
    call minimum => 1;
    call maximum => U();
    call limits  => [1, 0xffffffff];
  },
  'standalone with no maximum',
);

is(
  Wasm::Wasmtime::MemoryType->new({ minimum => 1, maximum => 100, is64 => 1 }),
  object {
    call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
    call minimum   => 1;
    call maximum   => 100;
    call is64      => T();
    call is_shared => F();
    call to_string => '1 100 i64';
  },
  'memory64 via hash ref',
);

is(
  Wasm::Wasmtime::MemoryType->new({ minimum => 1, maximum => 4, shared => 1 }),
  object {
    call is64      => F();
    call is_shared => T();
    call to_string => '1 4 shared';
  },
  'shared via hash ref',
);

is(
  Wasm::Wasmtime::MemoryType->new({ minimum => 0, page_size_log2 => 0 }),
  object {
    call page_size      => 1;
    call page_size_log2 => 0;
  },
  'custom page size via hash ref',
);

is(
  dies { Wasm::Wasmtime::MemoryType->new({ minimum => 1, page_size_log2 => 5 }) },
  match qr/page size/,
  'invalid page size dies',
);

done_testing;
