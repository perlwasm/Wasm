package Wasm::Wasmtime::Instance;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Module;

# ABSTRACT: Wasmtime instance class
# VERSION

$ffi->mangler(sub { "wasm_instance_$_[0]" });
$ffi->type('opaque' => 'wasm_instance_t');

$ffi->attach( new => ['wasm_store_t','wasm_module_t','opaque','opaque*'] => 'wasm_engine_t' => sub {
  my($xsub, $class, $module) = @_;
  my $trap;
  my $ptr = $xsub->($module->store->{ptr}, $module->{ptr}, undef, \$trap);
  if($ptr)
  {
    return bless {
      ptr    => $ptr,
      module => $module,
    }, $class;
  }
  else
  {
    # TODO: totally untested! not sure how to force this for a unit test.
    Carp::croak("error creating Wasm::Wasmtime::Instance " . $trap->message);
  }
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_engine_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
