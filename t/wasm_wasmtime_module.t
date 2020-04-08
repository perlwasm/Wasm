use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Wat2Wasm;

is(
  Wasm::Wasmtime::Module->new(wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
  },
  'autocreate store',
);

is(
  Wasm::Wasmtime::Module->new(Wasm::Wasmtime::Store->new, wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
  },
  'explicit store',
);

is(
  Wasm::Wasmtime::Module->new(wat => '(module)'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
  },
  'wat key',
);

is(
  Wasm::Wasmtime::Module->new(wasm => wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
  },
  'wasm key',
);

is(
  Wasm::Wasmtime::Module->new(file => 'examples/gcd.wat'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
  },
  'file key',
);

=pod

is(
  Wasm::Wasmtime::Module->validate(wat2wasm('(module)')),
  T(),
);

is(
  Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, wat2wasm('(module)')),
  T(),
);

is(
  Wasm::Wasmtime::Module->validate('f00f'),
  F(),
);

is(
  Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, 'f00f'),
  F(),
);

=cut

done_testing;
