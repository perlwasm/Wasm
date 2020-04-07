use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

imported_ok 'wat2wasm';

subtest 'good wat' => sub {

  my $engine = Wasm::Wasmtime::Engine->new;
  my $wasm = wat2wasm( "(module)" );
  isa_ok $wasm, 'Wasm::Wasmtime::ByteVec';

};

subtest 'good wat as vector' => sub {

  my $engine = Wasm::Wasmtime::Engine->new;
  my $vec = Wasm::Wasmtime::ByteVec->new("(module)");
  my $wasm = wat2wasm( $vec );
  isa_ok $wasm, 'Wasm::Wasmtime::ByteVec';

};

subtest 'bad wat' => sub {

  my $engine = Wasm::Wasmtime::Engine->new;

  local $@ = '';
  eval { wat2wasm( "f00f" ) };
  isnt "$@", "";

  note "$@";

};

done_testing;


