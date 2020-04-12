use strict;
use warnings;
use Wasm::Wasmtime;

my $store  = Wasm::Wasmtime::Store->new;
my $linker = Wasm::Wasmtime::Linker->new($store);

# Instanciate and define a WASI instance
my $wasi = Wasm::Wasmtime::WasiInstance->new(
  $store,
  "wasi_snapshot_preview1",
  Wasm::Wasmtime::WasiConfig
    ->new
    ->inherit_stdout
);
$linker->define_wasi($wasi);

# Create a logger module + instance
my $logger = $linker->instantiate(
  Wasm::Wasmtime::Module->new(
    $store,
    wat => q{
      (module
        (type $fd_write_ty (func (param i32 i32 i32 i32) (result i32)))
        (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (type $fd_write_ty)))

        (func (export "double") (param i32) (result i32)
          local.get 0
          i32.const 2
          i32.mul
        )

        (func (export "log") (param i32 i32)
          ;; store the pointer in the first iovec field
          i32.const 4
          local.get 0
          i32.store

          ;; store the length in the first iovec field
          i32.const 4
          local.get 1
          i32.store offset=4

          ;; call the `fd_write` import
          i32.const 1     ;; stdout fd
          i32.const 4     ;; iovs start
          i32.const 1     ;; number of iovs
          i32.const 0     ;; where to write nwritten bytes
          call $fd_write
          drop
        )

        (memory (export "memory") 2)
        (global (export "memory_offset") i32 (i32.const 65536))
      )
    },
  )
);
$linker->define_instance("logger", $logger);

# Create a caller module + instance
my $caller = $linker->instantiate(
  Wasm::Wasmtime::Module->new(
    $store,
    wat => q{
      (module
        (import "logger" "double" (func $double (param i32) (result i32)))
        (import "logger" "log" (func $log (param i32 i32)))
        (import "logger" "memory" (memory 1))
        (import "logger" "memory_offset" (global $offset i32))

        (func (export "run")
          ;; Call into the other module to double our number, and we could print it
          ;; here but for now we just drop it
          i32.const 2
          call $double
          drop

          ;; Our `data` segment initialized our imported memory, so let's print the
          ;; string there now.
          global.get $offset
          i32.const 14
          call $log
        )

        (data (global.get $offset) "Hello, world!\n")
      )
    },
  ),
);
$caller->get_export('run')->as_func->();
