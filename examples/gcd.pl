use strict;
use warnings;
use Path::Tiny qw( path );
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Instance;

my $store = Wasm::Wasmtime::Store->new;
my $module = Wasm::Wasmtime::Module->new( file => path(__FILE__)->parent->child('gcd.wat') );
my $instance = Wasm::Wasmtime::Instance->new($module);
