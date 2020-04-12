use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Linker;

my $instance = wasm_instance_ok( [], q{
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
});

my $module = $instance->module;
my $store  = $module->store;

is(
  Wasm::Wasmtime::Linker->new(
    $store,,
  ),
  object {
    call [ isa => 'Wasm::Wasmtime::Linker' ] => T();
    call [ allow_shadowing => 1 ] => D();
    call [ allow_shadowing => 0 ] => D();
    call [ define => 'xx', 'add', $instance->get_export('add') ] => D();
  },
  'basics'
);

done_testing;
