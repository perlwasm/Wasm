package Wasm::NWasmtime;

use strict;
use warnings;
use 5.008001;
use Alien::wasmtime;
use FFI::Platypus 1.00;
use FFI::Platypus::Buffer ();
use Carp ();
use base qw( Exporter );

# ABSTRACT: Write Perl interface to wasmtime
# VERSION

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => [Alien::wasmtime->dynamic_libs],
);

$ffi->bundle('Wasm');

# private class
{ package Wasm::NWasmtime::Vec;
  use FFI::Platypus::Record;
  record_layout_1(
    $ffi,
    size_t => 'size',
    opaque => 'data',
  );
}

{ package Wasm::NWasmtime::ByteVec;
  use base qw( Wasm::NWasmtime::Vec );

  $ffi->type( 'record(Wasm::NWasmtime::ByteVec)' => 'wasm_byte_vec_t' );

  $ffi->attach( [ 'wasm_byte_vec_new' => 'set' ] => [ 'wasm_byte_vec_t*', 'size_t', 'opaque' ] => sub {
    my $xsub = shift;
    my $self = shift;
    my($data, $size) = FFI::Platypus::Buffer::scalar_to_buffer $_[0];
    $self->data($data);
    $self->size($size);
  });

  sub get
  {
    my $self = shift;
    FFI::Platypus::Buffer::buffer_to_scalar(
      $self->data,
      $self->size,
    );
  }

  $ffi->attach( ['wasm_byte_vec_delete' => 'DESTROY'] => ['wasm_byte_vec_t*'] => sub {
    my($xsub, $self) = @_;
    $xsub->($self);
    $self->SUPER::DESTROY;
  });  
}

$ffi->attach(wasmtime_wat2wasm => [ 'wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*' ] => 'bool' => sub {
  my $xsub = shift;
  my $wat = Wasm::NWasmtime::ByteVec->new;
  $wat->set($_[0]);
  my $ret = Wasm::NWasmtime::ByteVec->new;
  my $error_message = Wasm::NWasmtime::ByteVec->new;
  if($xsub->($wat, $ret, $error_message))
  {
    return $ret->get;
  }
  else
  {
    Carp::croak $error_message->get . "\nwat2wasm error";
  }
});

$ffi->type('opaque' => 'wasm_config_t');
$ffi->type('opaque' => 'wasm_engine_t');
$ffi->type('opaque' => 'wasm_store_t');
$ffi->type('opaque' => 'wasm_module_t');
$ffi->type('opaque' => 'wasm_trap_t');
$ffi->type('opaque' => 'wasm_instance_t');

$ffi->attach( wasm_config_new             => []                => 'wasm_config_t' );
$ffi->attach( wasm_config_delete          => ['wasm_config_t'] => 'void'          );
$ffi->attach( wasm_engine_new             => []                => 'wasm_engine_t' );
$ffi->attach( wasm_engine_new_with_config => ['wasm_config_t'] => 'wasm_engine_t' );
$ffi->attach( wasm_engine_delete          => ['wasm_engine_t'] => 'void'          );
$ffi->attach( wasm_store_new              => ['wasm_engine_t'] => 'wasm_store_t'  );
$ffi->attach( wasm_store_delete           => ['wasm_store_t']  => 'void'          );

foreach my $prop (qw( debug_info wasm_threads wasm_reference_types wasm_simd wasm_bulk_memory wasm_multi_value cranelift_debug_verifier ))
{
  $ffi->attach( "wasmtime_config_${prop}_set" => ['wasm_config_t', 'bool' ] => 'void' );
}

$ffi->attach( wasmtime_config_strategy_set            => ['wasm_config_t', 'uint8'] => 'bool' );
$ffi->attach( wasmtime_config_cranelift_opt_level_set => ['wasm_config_t', 'uint8'] => 'void' );
$ffi->attach( wasmtime_config_profiler_set            => ['wasm_config_t', 'uint8'] => 'bool' );

$ffi->attach( wasm_module_new => ['wasm_store_t', 'wasm_byte_vec_t*' ] => 'wasm_module_t' => sub {
  my $xsub = shift;
  my $store = shift;
  my $wasm = Wasm::NWasmtime::ByteVec->new;
  $wasm->set($_[0]);
  $xsub->($store, $wasm);
});

$ffi->attach( wasm_module_validate => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'bool' => sub {
  my $xsub = shift;
  my $store = shift;
  my $wasm = Wasm::NWasmtime::ByteVec->new;
  $wasm->set($_[0]);
  $xsub->($store, $wasm);
});

#$ffi->attach( wasm_module_serialize => ['wasm_module_t', 'wasm_byte_vec_t*' ] => 'void' => sub {
#  my($xsub, $mod) = @_;
#  my $out = Wasm::NWasmtime::ByteVec->new;
#  $xsub->($mod, $out);
#  $out->get;
#});

#$ffi->attach( wasm_module_deserialize => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'wasm_module_t' => sub {
#  my $xsub = shift;
#  my $store = shift;
#  my $in = Wasm::NWasmtime::ByteVec->new;
#  $in->set($_[0]);
#  $xsub->($store, $in);
#});

$ffi->attach( wasm_module_delete => ['wasm_module_t'] => 'void' );

$ffi->attach( wasm_trap_new => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $store = shift;
  my $message = Wasm::NWasmtime::ByteVec->new;
  $message->set($_[0]);
  $xsub->($store, $message);  
});
$ffi->attach( wasm_trap_message => ['wasm_trap_t','wasm_byte_vec_t*'] => sub {
  my($xsub, $trap) = @_;
  my $message = Wasm::NWasmtime::ByteVec->new;
  $xsub->($trap, $message);
  $message->get;
});
$ffi->attach( wasm_trap_delete => ['wasm_trap_t'] => 'void');

$ffi->attach( wasm_instance_new => ['wasm_store_t', 'wasm_module_t', 'opaque', 'opaque*'] => 'wasm_instance_t' => sub {
  my($xsub, $store, $mod) = @_;
  # TODO: third argument is wasm_extern_t*[]
  my $trap;
  my $instance = $xsub->($store, $mod, undef, \$trap);
  unless(defined $instance)
  {
    my $message = wasm_trap_message($trap);
    Carp::croak("error creating wasm_instance_t $message");
  }
  $instance;
});

$ffi->attach( wasm_instance_delete => ['wasm_instance_t'] );

our @EXPORT = (grep /^(WASM_|WASMTIME_|wasm_|wasmtime_)/, keys %Wasm::NWasmtime::);

1;
