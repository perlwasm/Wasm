use strict;
use warnings;

$ENV{WASM_WASMTIME_FFI} = '/home/ollisg/opt/wasmtime/0.28.0/lib/libwasmtime.so';

exec @ARGV if @ARGV;

my %wt_tests = map { $_ => 1 } qw(
  t/00_diag.t
  t/test2_plugin_wasm.t
  t/wasm_wasmtime.t
  t/wasm_wasmtime_bytevec.t
  t/wasm_wasmtime_caller.t
  t/wasm_wasmtime_config.t
  t/wasm_wasmtime_context.t
  t/wasm_wasmtime_engine.t
  t/wasm_wasmtime_exporttype.t
  t/wasm_wasmtime_extern.t
  t/wasm_wasmtime_externtype.t
  t/wasm_wasmtime_ffi.t
  t/wasm_wasmtime_func.t
  t/wasm_wasmtime_functype.t
  t/wasm_wasmtime_global.t
  t/wasm_wasmtime_globaltype.t
  t/wasm_wasmtime_importtype.t
  t/wasm_wasmtime_instance.t
  t/wasm_wasmtime_instance_exports.t
  t/wasm_wasmtime_linker.t
  t/wasm_wasmtime_memory.t
  t/wasm_wasmtime_memorytype.t
  t/wasm_wasmtime_module.t
  t/wasm_wasmtime_moduletype_exports.t
  t/wasm_wasmtime_moduletype_imports.t
  t/wasm_wasmtime_moduletype.t
  t/wasm_wasmtime_store.t
  t/wasm_wasmtime_table.t
  t/wasm_wasmtime_tabletype.t
  t/wasm_wasmtime_trap.t
  t/wasm_wasmtime_valtype.t
  t/wasm_wasmtime_wasiconfig.t
  t/wasm_wasmtime_wasiinstance.t
  t/wasm_wasmtime_wat2wasm.t
);

delete $wt_tests{$_} for qw( t/wasm_wasmtime_caller.t t/wasm_wasmtime_extern.t t/wasm_wasmtime_func.t t/wasm_wasmtime_global.t t/wasm_wasmtime_instance.t
                             t/wasm_wasmtime_instance_exports.t t/wasm_wasmtime_linker.t t/wasm_wasmtime_memory.t t/wasm_wasmtime_table.t
                             t/wasm_wasmtime_trap.t );

my @wt_tests = sort keys %wt_tests;

exec 'prove', '-l', @wt_tests;
