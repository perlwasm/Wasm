use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::FFI ();

my $vec = Wasm::Wasmtime::ByteVec->new("foo");
isa_ok $vec, 'Wasm::Wasmtime::ByteVec';
is $vec->get, 'foo';

done_testing;
