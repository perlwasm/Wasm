use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

subtest 'string input' => sub {
  my $engine = Wasm::Wasmtime::Engine->new;
  my $store = Wasm::Wasmtime::Store->new($engine);
  my $trap = Wasm::Wasmtime::Trap->new($store, "frooble");

  isa_ok $trap, 'Wasm::Wasmtime::Trap';
  is $trap->message, "frooble";
};

subtest 'vec input' => sub {
  my $engine = Wasm::Wasmtime::Engine->new;
  my $store = Wasm::Wasmtime::Store->new($engine);
  my $vec = Wasm::Wasmtime::ByteVec->new("frooble\0");
  my $trap = Wasm::Wasmtime::Trap->new($store, $vec);

  isa_ok $trap, 'Wasm::Wasmtime::Trap';
  is $trap->message, "frooble";
};

done_testing;


