use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;
use Path::Tiny qw( path );

subtest 'basic' => sub {
  my $engine = Wasm::Wasmtime::Engine->new;
  my $wasm   = wat2wasm( path("corpus/gcd.wat")->slurp );
  my $store  = Wasm::Wasmtime::Store->new($engine);
  my $mod = Wasm::Wasmtime::Module->new($store, $wasm);

  my $instance = Wasm::Wasmtime::Instance->new($store, $mod);
  isa_ok $instance, 'Wasm::Wasmtime::Instance';

  my $externs = $instance->exports;

  is(
    $externs,
    object {
      call ['isa', 'Wasm::Wasmtime::ExternVec'] => T();
      call size => 1;
      call_list to_list => array {
        item object {
          call ['isa', 'Wasm::Wasmtime::Func'] => T();
        };
        end;
      };
    },
  );


};

done_testing;


