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
    call_list exports => array {
      item object {
        call type => object {
          call as_memorytype => object {
            call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
            call_list limits => [2,6];
          };
        };
      };
      end;
    };
  },
  'memorytype class basics',
);

done_testing;
