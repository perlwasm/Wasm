package Wasm::Wasmtime::WasiInstance;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Trap;
use Wasm::Wasmtime::WasiConfig;

# ABSTRACT: WASI instance class
# VERSION

$ffi_prefix = 'wasi_instance_';
$ffi->custom_type('wasi_instance_t' => {
  native_type => 'opaque',
  perl_to_native => sub { shift->{ptr} },
  native_to_perl => sub { bless { ptr => shift }, __PACKAGE__ },
});

$ffi->attach( new => ['wasm_store_t', 'string', 'wasi_config_t', 'wasm_trap_t*'] => 'wasi_instance_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $store = shift;
  my $name = shift;
  my $config = defined $_[0] && ref($_[0]) eq 'Wasm::Wasmtime::WasiConfig' ? shift : Wasm::Wasmtime::WasiConfig->new;
  my $trap;
  my $instance = $xsub->($store->{ptr}, $name, $config, \$trap);
  delete $config->{ptr};
  unless($instance)
  {
    if($trap)
    {
      my $message = Wasm::Wasmtime::Trap->new($trap)->message;
      Carp::croak($message);
    }
    Carp::croak("failed to create wasi instance");
  }
  $instance;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasi_instance_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self) if $self->{ptr};
});

1;
