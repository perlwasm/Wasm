use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Instance;

is(
  Wasm::Wasmtime::Instance->new(Wasm::Wasmtime::Module->new(wat => '(module)')),
  object {
    call [ isa => 'Wasm::Wasmtime::Instance' ] => T();
    call module => object {
      call [ isa => 'Wasm::Wasmtime::Module' ] => T();
    };
  },
  'created instance instance'
);

is(
  Wasm::Wasmtime::Instance->new(Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "sub") (param i64 i64) (result i64)
        local.get 0
        local.get 1
        i64.sub)
      (memory (export "frooble") 2 3)
    )
  })),
  object {
    call [ isa => 'Wasm::Wasmtime::Instance' ] => T();
    call [ get_export => 'add' ] => object {
      call [isa => 'Wasm::Wasmtime::Extern'] => T();
    };
    call [ get_export => 'foo' ] => U();
    call_list exports => array {
      item object {
        call [isa => 'Wasm::Wasmtime::Extern'] => T();
        call type => object {
          call [isa => 'Wasm::Wasmtime::ExternType'] => T();
          call kind => 'func';
          call as_functype => object {
            call_list params => array {
              item object { call kind => 'i32' };
              item object { call kind => 'i32' };
              end;
            };
          };
        };
        call as_func => object {
          call [isa => 'Wasm::Wasmtime::Func'] => T();
          call type => object {
            call [isa => 'Wasm::Wasmtime::FuncType'] => T();
          };
        };
      };
      item object {
        call [isa => 'Wasm::Wasmtime::Extern'] => T();
        call type => object {
          call [isa => 'Wasm::Wasmtime::ExternType'] => T();
          call kind => 'func';
          call as_functype => object {
            call_list params => array {
              item object { call kind => 'i64' };
              item object { call kind => 'i64' };
              end;
            };
          };
        };
      };
      item object {
        call [isa => 'Wasm::Wasmtime::Extern'] => T();
        call type => object {
          call [isa => 'Wasm::Wasmtime::ExternType'] => T();
          call kind => 'memory';
        };
      };
      end;
    };
  },
  'created exports'
);

done_testing;
