use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

subtest 'basic' => sub {
  my $engine = Wasm::Wasmtime::Engine->new;
  my $wasm   = wat2wasm( $engine, "(module)" );
  my $store  = Wasm::Wasmtime::Store->new($engine);
  my $mod = Wasm::Wasmtime::Module->new($store, $wasm);

  my $instance = Wasm::Wasmtime::Instance->new($store, $mod);
  isa_ok $instance, 'Wasm::Wasmtime::Instance';
};

done_testing;


