use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

my $engine = Wasm::Wasmtime::Engine->new;
my $store = Wasm::Wasmtime::Store->new($engine);
isa_ok $store, 'Wasm::Wasmtime::Store';

done_testing;


