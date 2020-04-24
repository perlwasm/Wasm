package Wasm::Wasmtime::Global;

use strict;
use warnings;
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::GlobalType;
use Wasm::Wasmtime::CBC qw( perl_to_wasm wasm_allocate wasm_to_perl );

# ABSTRACT: Wasmtime global class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/global.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly global object.

=cut

$ffi_prefix = 'wasm_global_';
$ffi->type('opaque' => 'wasm_global_t');

=head1 CONSTRUCTOR

=head2 new

 my $global = Wasm::Wasmtime::Global->new(
   $store,      # Wasm::Wasmtime::Store
   $globaltype, # Wasm::Wasmtime::GlobalType
 );

Creates a new global object.

=cut

$ffi->attach( new => ['wasm_store_t', 'wasm_globaltype_t', 'string'] => 'wasm_global_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(is_ref $_[0])
  {
    my($store, $globaltype, $value) = @_;
    $ptr = $xsub->($store, $globaltype->{ptr}, perl_to_wasm([$value], [$globaltype->content]));
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
});

=head1 METHODS

=head2 type

 my $globaltype = $global->type;

Returns the L<Wasm::Wasmtime::GlobalType> object for this global object.

=cut

$ffi->attach( type => ['wasm_global_t'] => 'wasm_globaltype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::GlobalType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});

=head2 get

 my $value = $global->get;

Gets the global value.

=cut

$ffi->attach( get => ['wasm_global_t', 'string'] => sub {
  my($xsub, $self) = @_;
  my $value = wasm_allocate(1);
  $xsub->($self->{ptr}, $value);
  ($value) = wasm_to_perl($value);
  $value;
});

=head2 set

 my $global->set($value);

Sets the global to the given value.

=cut

$ffi->attach( set => ['wasm_global_t','string'] => sub {
  my($xsub, $self, $value) = @_;
  $xsub->($self->{ptr}, perl_to_wasm([$value],[$self->type->content]));
});

=head2 as_extern

 my $extern = $global->as_extern;

Returns the L<Wasm::Wasmtime::Extern> for this global object.

=cut

# actually returns a wasm_extern_t, but recursion
$ffi->attach( as_extern => ['wasm_global_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::Extern;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::Extern->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_global_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

