use strict;
use warnings;
use File::Glob qw( bsd_glob );

$ENV{WASM_WASMTIME_FFI} = '/home/ollisg/opt/wasmtime/0.28.0/lib/libwasmtime.so';

exec @ARGV if @ARGV;

my %wt_tests = map { $_ => 1 } bsd_glob('t/wasm_wasmtime*.t');
$wt_tests{'t/00_diag.t'} = 1;

delete $wt_tests{$_} for qw(
t/wasm_wasmtime_caller.t
t/wasm_wasmtime_extern.t
t/wasm_wasmtime_func.t
t/wasm_wasmtime_global.t
t/wasm_wasmtime_instance.t
t/wasm_wasmtime_instance_exports.t
t/wasm_wasmtime_linker.t
t/wasm_wasmtime_memory__integration.t
t/wasm_wasmtime_table.t
t/wasm_wasmtime_trap.t
);

my @wt_tests = sort keys %wt_tests;

exec 'prove', '-l', @wt_tests;
