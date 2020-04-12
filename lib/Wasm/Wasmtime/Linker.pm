package Wasm::Wasmtime::Linker;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;

# ABSTRACT: Wasmtime linker class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/linker.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly linker.

=cut

$ffi_prefix = 'wasmtime_linker_';
$ffi->type('opaque' => 'wasmtime_linker_t');

=head1 CONSTRUCTOR

=head2 new

 my $linker = Wasm::Wasmtime::Linker->new(
   $store,        # Wasm::Wasmtime::Store
 );

Create a new WebAssembly linker object.

=cut

$ffi->attach( new => ['wasm_store_t'] => 'wasmtime_linker_t' => sub {
  my($xsub, $class, $store) = @_;
  my $ptr = $xsub->($store->{ptr});
  bless { ptr => $ptr, store => $store }, $class;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasmtime_linker_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
