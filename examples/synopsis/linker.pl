use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $linker = Wasm::Wasmtime::Linker->new($store);
