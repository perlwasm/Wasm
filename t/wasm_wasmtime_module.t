use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

subtest 'basic' => sub {

  my $engine = Wasm::Wasmtime::Engine->new;
  my $wasm   = wat2wasm( "(module)" );
  my $store  = Wasm::Wasmtime::Store->new($engine);

  is(
    Wasm::Wasmtime::Module->validate($store, $wasm),
    T(),
    'validate',
  );

  my $mod = Wasm::Wasmtime::Module->new($store, $wasm);
  isa_ok $mod, 'Wasm::Wasmtime::Module';

};

done_testing;


