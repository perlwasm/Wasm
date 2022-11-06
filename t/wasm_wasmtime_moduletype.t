use 5.008004;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::ModuleType;

skip_all '0.28.0 and better only' unless Wasm::Wasmtime::FFI::_ver ne '0.27.0';

my $wasm_binary = "\0asm\x01\0\0\0";

is(
  Wasm::Wasmtime::Module->new($wasm_binary),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call type => object {
      call ['isa', 'Wasm::Wasmtime::ModuleType' ] => T();
      call exports => object {};
    };
  },
  'basic create',
);

done_testing;
