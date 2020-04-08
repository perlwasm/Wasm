use strict;
use warnings;
use Path::Tiny qw( path );
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Module;

my $store = Wasm::Wasmtime::Store->new;
my $module = Wasm::Wasmtime::Module->new( file => path(__FILE__)->parent->child('gcd.wat') );
