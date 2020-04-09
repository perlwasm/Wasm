use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Memory;

is(
  wasm_instance_ok(q{
    (module
      (memory (export "frooble") 2 6)
    )
  }),
  object {
    call [get_export => 'frooble'] => object {
      call [ isa => 'Wasm::Wasmtime::Extern' ] => T();
      call as_memory => object {
        call [ isa => 'Wasm::Wasmtime::Memory' ] => T();
        call type => object {
          call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
        };
        call data => match qr/^[0-9]+$/;
        call data_size => match qr/^[0-9]+$/;
        call size => 2;
        call [ grow => 3] => T();
        call size => 5;
      };
    };
  },
  'memory class basics',
);

done_testing;
