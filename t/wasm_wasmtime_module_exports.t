use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Module::Exports;
use YAML qw( Dump );

{
  my $module = Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
    )
  });
  my $exports = Wasm::Wasmtime::Module::Exports->new($module);
  is(
    $exports,
    object {
      call [ isa => 'Wasm::Wasmtime::Module::Exports' ] => T();
      call add => object {
        call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
      };
    },
    'exports object looks good'
  );
  note Dump($exports);
}

done_testing;
