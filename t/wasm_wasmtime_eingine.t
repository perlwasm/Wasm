use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

my $engine = Wasm::Wasmtime::Engine->new;
isa_ok $engine, 'Wasm::Wasmtime::Engine';

done_testing;


