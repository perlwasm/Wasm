use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

my $engine = Wasm::Wasmtime::Config->new;
isa_ok $engine, 'Wasm::Wasmtime::Config';

done_testing;


