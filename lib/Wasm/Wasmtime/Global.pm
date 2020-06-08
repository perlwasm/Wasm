package Wasm::Wasmtime::Global;

use strict;
use warnings;
use 5.008004;
use base qw( Wasm::Wasmtime::Extern );
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::GlobalType;
use constant is_global => 1;
use constant kind => 'global';

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
$ffi->load_custom_type('::PtrObject' => 'wasm_global_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $global = Wasm::Wasmtime::Global->new(
   $store,      # Wasm::Wasmtime::Store
   $globaltype, # Wasm::Wasmtime::GlobalType
 );

Creates a new global object.

=cut

$ffi->attach( new => ['wasm_store_t', 'wasm_globaltype_t', 'wasm_val_t'] => 'wasm_global_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(is_ref $_[0])
  {
    my($store, $globaltype, $value) = @_;
    $value = Wasm::Wasmtime::Val->new({
      kind => $globaltype->content->kind_num,
      of => { $globaltype->content->kind => $value },
    });
    my $self = $xsub->($store, $globaltype, $value);
    $self->{store} = $store;
    return $self;
  }
  else
  {
    my($ptr, $owner) = @_;
    bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});

=head1 METHODS

=head2 type

 my $globaltype = $global->type;

Returns the L<Wasm::Wasmtime::GlobalType> object for this global object.

=cut

$ffi->attach( type => ['wasm_global_t'] => 'wasm_globaltype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});

=head2 get

 my $value = $global->get;

Gets the global value.

=cut

$ffi->attach( get => ['wasm_global_t', 'wasm_val_t'] => sub {
  my($xsub, $self) = @_;
  my $value = Wasm::Wasmtime::Val->new;
  $xsub->($self, $value);
  $value->to_perl;
});

=head2 set

 my $global->set($value);

Sets the global to the given value.

=cut

$ffi->attach( set => ['wasm_global_t','wasm_val_t'] => sub {
  my($xsub, $self, $value) = @_;
    $value = Wasm::Wasmtime::Val->new({
      kind => $self->type->content->kind_num,
      of => { $self->type->content->kind => $value },
    });
  $xsub->($self, $value);
});

=head2 tie

 my $ref = $global->tie;

Returns a reference to a tied scalar that can be used to get/set the global.

=cut

sub tie
{
  my $self = shift;
  my $ref;
  tie $ref, __PACKAGE__, $self;
  \$ref;
}

sub TIESCALAR { $_[1] }
*FETCH = \&get;
*STORE = \&set;

__PACKAGE__->_cast(1);
_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
