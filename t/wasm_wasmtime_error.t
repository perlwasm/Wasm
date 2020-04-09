use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Error;

skip_all 'test requires wasmtime_erorr_t' unless $ffi->find_symbol('wasmtime_error_message');

diag 'todo';

ok 1;

done_testing;
