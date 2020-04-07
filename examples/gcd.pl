use strict;
use warnings;
use 5.008001;
use Wasm::NWasmtime;
use Path::Tiny qw( path );

my $engine = wasm_engine_new();
my $store  = wasm_store_new($engine);
my $wat = path(__FILE__)->parent->child('gcd.wat')->slurp_utf8;
our $wasm = wasmtime_wat2wasm($wat);
my $module = wasm_module_new($store, $wasm);
my $instance = wasm_instance_new($store, $module);

wasm_instance_delete($instance);
wasm_module_delete($module);
wasm_store_delete($store);
wasm_engine_delete($engine);
