package Wasm::Wasmtime::Trap;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;

# ABSTRACT: Wasmtime trap class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/trap.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a trap, usually something unexpected that happened in Wasm land.
This is usually converted into an exception in Perl land, but you can create your
own trap here.

=cut

$ffi_prefix = 'wasm_trap_';
$ffi->type('opaque' => 'wasm_trap_t');

=head1 CONSTRUCTORS

=head2 new

 my $trap = Wasm::Wasmtime::Trap->new(
   $store,    # Wasm::Wasmtime::Store
   $message,  # Null terminated string
 );

Create a trap instance.  C<$message> MUST be null terminated.

=cut

$ffi->attach( new => [ 'wasm_store_t', 'wasm_byte_vec_t*' ] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(@_ == 1)
  {
    my $pointer = shift;
    return bless {
      ptr => $pointer,
    }, $class;
  }
  else
  {
    my $store = shift;
    my $message = Wasm::Wasmtime::ByteVec->new($_[0]);
    return bless {
      ptr => $xsub->($store->{ptr}, $message),
    }, $class;
  }
});

=head1 METHODS

=head2 message

 my $message = $trap->message;

Returns the trap message as a string.

=cut

$ffi->attach( message => ['wasm_trap_t', 'wasm_byte_vec_t*'] => sub {
  my($xsub, $self) = @_;
  my $message = Wasm::Wasmtime::ByteVec->new;
  $xsub->($self->{ptr}, $message);
  my $ret = $message->get;
  $ret =~ s/\0$//;
  $message->delete;
  $ret;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_trap_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
