use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

isa_ok(
  Wasm::Wasmtime::Engine->new,
  'Wasm::Wasmtime::Engine',
);

{
  my $config = Wasm::Wasmtime::Config->new;

  isa_ok(
    Wasm::Wasmtime::Engine->new($config),
    'Wasm::Wasmtime::Engine',
  );
}

done_testing;


