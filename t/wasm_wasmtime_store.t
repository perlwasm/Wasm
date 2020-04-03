use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new(Wasm::Wasmtime::Engine->new);
isa_ok $store, 'Wasm::Wasmtime::Store';

done_testing;


