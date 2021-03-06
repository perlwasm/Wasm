package Wasm::Wasmtime::WasiInstance;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Trap;
use Wasm::Wasmtime::WasiConfig;

# ABSTRACT: WASI instance class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/wasiinstance.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the WebAssembly System Interface (WASI).  For WebAssembly WASI is the
equivalent to the part of libc that interfaces with the system.

To configure if and how the WASI accesses program argument, environment, standard streams
and file system directories, see L<Wasm::Wasmtime::WasiConfig>.

For a complete example of using WASI from WebAssembly, see the synopsis for
L<Wasm::Wasmtime::Linker>.

=cut

$ffi_prefix = 'wasi_instance_';
$ffi->load_custom_type('::PtrObject' => 'wasi_instance_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $wasi = Wasm::Wasmtime::WasiInstance->new(
   $store,   # Wasm::Wasmtime::Store,
   $name,    # string
   $config,  # Wasm::Wasmtime::WasiConfig,
 );
 my $wasi = Wasm::Wasmtime::WasiInstance->new(
   $store,   # Wasm::Wasmtime::Store,
   $name,    # string
 );

Create a new WASI instance.

=cut

$ffi->attach( new => ['wasm_store_t', 'string', 'wasi_config_t', 'opaque*'] => 'wasi_instance_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $store = shift;
  my $name = shift;
  my $config = defined $_[0] && ref($_[0]) eq 'Wasm::Wasmtime::WasiConfig' ? shift : Wasm::Wasmtime::WasiConfig->new;
  my $trap;
  my $instance = $xsub->($store, $name, $config, \$trap);
  delete $config->{ptr};
  unless($instance)
  {
    if($trap)
    {
      die Wasm::Wasmtime::Trap->new($trap);
    }
    Carp::croak("failed to create wasi instance");
  }
  $instance;
});

# TODO: bind_import

_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
