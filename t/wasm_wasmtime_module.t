use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Wat2Wasm;

is(
  Wasm::Wasmtime::Module->new(wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'autocreate store',
);

is(
  Wasm::Wasmtime::Module->new(Wasm::Wasmtime::Store->new, wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'explicit store',
);

is(
  Wasm::Wasmtime::Module->new(wat => '(module)'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'wat key',
);

is(
  Wasm::Wasmtime::Module->new(wasm => wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'wasm key',
);

is(
  Wasm::Wasmtime::Module->new(file => 'examples/gcd.wat'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'file key',
);

is(
  Wasm::Wasmtime::Module->validate(wat2wasm('(module)')),
  T(),
  'validate good',
);

is(
  Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, wat2wasm('(module)')),
  T(),
  'validate good with store',
);

is(
  Wasm::Wasmtime::Module->validate('f00f'),
  F(),
  'validate bad',
);

is(
  Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, 'f00f'),
  F(),
  'validate bad with store',
);

is(
  Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "sub") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.sub)
    )
  }),
  object {
    call_list exports => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'add';
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'sub';
      };
      end;
    };
  },
  'exports',
);

done_testing;
