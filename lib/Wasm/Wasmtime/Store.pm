package Wasm::Wasmtime::Store;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Context;
use Wasm::Wasmtime::Engine;

# TODO: wasmtime_store_add_fuel
# TODO: wasmtime_store_fuel_consumed

# ABSTRACT: Wasmtime store class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/store.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents storage used by the WebAssembly engine.

=cut

if(_ver ne '0.27.0')
{
  $ffi_prefix = 'wasmtime_store_';
}
else
{
  $ffi_prefix = 'wasm_store_';
}
# TODO: we should change this to a wasmtime_store_t at some point
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

if(_ver ne '0.27.0')
{
  $ffi->attach( new => ['wasm_engine_t','opaque','(opaque)->void'] => 'wasm_store_t' => sub {
    my($xsub, $class, $engine) = @_;
    $engine ||= Wasm::Wasmtime::Engine->new;
    my $self = $xsub->($engine,undef,undef);
    $self->{engine} = $engine;
    $self;
  });
}
else
{
  $ffi->attach( new => ['wasm_engine_t'] => 'wasm_store_t' => sub {
    my($xsub, $class, $engine) = @_;
    $engine ||= Wasm::Wasmtime::Engine->new;
    my $self = $xsub->($engine);
    $self->{engine} = $engine;
    $self;
  });
}

=head2 context

 my $context = $store->context;

Returns the L<Wasm::Wasmtime::Context> for this store.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( context => ['wasm_store_t'] => 'wasmtime_context_t' => sub {
    my($xsub, $self) = @_;
    my $context = $xsub->($self);
    $context->{store} = $self;
    $context;
  });
}
else
{
  *context = sub {
    require Carp;
    Carp::croak("Context is not available in 0.27.0");
  };
}

=head2 gc

[deprecated use $store->context->gc instead]

 $store->gc;

Garbage collects C<externref>s that are used within this store. Any
C<externref>s that are discovered to be unreachable by other code or objects
will have their finalizers run.

=cut

if(_ver ne '0.27.0')
{
  *gc = sub {
    my($self) = @_;
    $self->context->gc;
  };
}
else
{
  $ffi->attach( [ wasmtime_store_gc => 'gc' ] => ['wasm_store_t'] => 'void' );
}

=head2 engine

 my $engine = $store->engine;

Returns the L<Wasm::Wasmtime::Engine> object for this storage object.

=cut

sub engine { shift->{engine} }

_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
