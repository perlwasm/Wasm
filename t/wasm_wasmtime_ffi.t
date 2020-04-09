use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::FFI;

diag '';
diag '';
diag '';

diag "_lib = $_" for Wasm::Wasmtime::FFI->_lib;

diag '';
diag '';

imported_ok '$ffi';
isa_ok $ffi, 'FFI::Platypus';

done_testing;
