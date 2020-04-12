package Wasm::Wasmtime::Store;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Engine;

# ABSTRACT: Wasmtime store class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/store.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents storage used by the WebAssembly engine.

=cut

$ffi_prefix = 'wasm_store_';
$ffi->type('opaque' => 'wasm_store_t');

=head1 CONSTRUCTOR

=head2 new

 my $store = Wasm::Wasmtime::Store->new;
 my $store = Wasm::Wasmtime::Store->new(
   $engine,   # Wasm::Wasmtime::Engine
 );

Creates a new storage instance.  If the optional L<Wasm::Wasmtime::Engine> object
isn't provided, then a new one will be created.

=cut

$ffi->attach( new => ['wasm_engine_t'] => 'wasm_store_t' => sub {
  my($xsub, $class, $engine) = @_;
  $engine ||= Wasm::Wasmtime::Engine->new;
  bless {
    ptr    => $xsub->($engine->{ptr}),
    engine => $engine,
  }, $class;
});

=head2 engine

 my $engine = $store->engine;

Returns the L<Wasm::Wasmtime::Engine> object for this storage object.

=cut

sub engine { shift->{engine} }

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_store_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

