package Wasm::Wasmtime::Store;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Engine;
use Ref::Util qw( is_blessed_ref );
use Carp ();

# ABSTRACT: Wasmtime store class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/store.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents storage used by the WebAssembly engine.  In the modern
Wasmtime C API almost every operation on a live WebAssembly object (function,
memory, global, table, instance) is performed relative to a store, via its
C<wasmtime_context_t>.  The L</context> method exposes that pointer for internal
use by the other L<Wasm::Wasmtime> classes.

=cut

$ffi_prefix = 'wasm_store_';
$ffi->load_custom_type('::PtrObject' => 'wasm_store_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $store = Wasm::Wasmtime::Store->new;
 my $store = Wasm::Wasmtime::Store->new(
   $engine,   # Wasm::Wasmtime::Engine
 );

Creates a new storage instance.  If the optional L<Wasm::Wasmtime::Engine> object
isn't provided, then a new one will be created.

=cut

$ffi->attach( [ wasmtime_store_new => 'new' ] => ['wasm_engine_t', 'opaque', 'opaque'] => 'opaque' => sub {
  my($xsub, $class, $engine) = @_;
  $engine ||= Wasm::Wasmtime::Engine->new;
  my $ptr = $xsub->($engine, undef, undef);
  my $self = bless {
    ptr    => $ptr,
    engine => $engine,
  }, $class;
  $self->{context} = _context($ptr);
  $self;
});

$ffi->attach( [ wasmtime_store_context => '_context' ] => ['opaque'] => 'opaque' );

=head1 METHODS

=head2 context

 my $context = $store->context;

Returns the C<wasmtime_context_t> pointer (an C<opaque>) for this store.  This
is primarily for internal use by other L<Wasm::Wasmtime> classes.

=cut

sub context { shift->{context} }

=head2 engine

 my $engine = $store->engine;

Returns the L<Wasm::Wasmtime::Engine> object for this storage object.

=cut

sub engine { shift->{engine} }

=head2 gc

 $store->gc;

Garbage collects C<externref>s that are used within this store.

=cut

$ffi->attach( [ wasmtime_context_gc => 'gc' ] => ['opaque'] => 'wasmtime_error_t' => sub {
  my($xsub, $self) = @_;
  my $error = $xsub->($self->{context});
  Carp::croak($error->message) if $error;
  return;
});

=head2 set_fuel

 $store->set_fuel($fuel);

Sets the amount of fuel available for WebAssembly to consume while executing.
Requires that the engine was configured with C<< $config->consume_fuel(1) >>.

=head2 get_fuel

 my $fuel = $store->get_fuel;

Returns the amount of fuel remaining in this store.

=cut

$ffi->attach( [ wasmtime_context_set_fuel => 'set_fuel' ] => ['opaque','uint64'] => 'wasmtime_error_t' => sub {
  my($xsub, $self, $fuel) = @_;
  my $error = $xsub->($self->{context}, $fuel);
  Carp::croak($error->message) if $error;
  $self;
});

$ffi->attach( [ wasmtime_context_get_fuel => 'get_fuel' ] => ['opaque','uint64*'] => 'wasmtime_error_t' => sub {
  my($xsub, $self) = @_;
  my $fuel = 0;
  my $error = $xsub->($self->{context}, \$fuel);
  Carp::croak($error->message) if $error;
  $fuel;
});

=head2 set_wasi

 $store->set_wasi($wasi_config);

Configures the WASI state for instances created within this store.  Takes
ownership of the L<Wasm::Wasmtime::WasiConfig> object (it must not be used
afterwards).

=cut

$ffi->attach( [ wasmtime_context_set_wasi => 'set_wasi' ] => ['opaque','opaque'] => 'wasmtime_error_t' => sub {
  my($xsub, $self, $wasi_config) = @_;
  Carp::croak("not a Wasm::Wasmtime::WasiConfig")
    unless is_blessed_ref($wasi_config) && $wasi_config->isa('Wasm::Wasmtime::WasiConfig');
  my $ptr = delete $wasi_config->{ptr};
  my $error = $xsub->($self->{context}, $ptr);
  Carp::croak($error->message) if $error;
  $self;
});

_generate_destroy('wasmtime_store_delete');

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
