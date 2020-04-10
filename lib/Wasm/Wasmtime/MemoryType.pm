package Wasm::Wasmtime::MemoryType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime memory type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/memorytype.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a module memory type.  It models the minimum and
maximum number of pages.

=cut

$ffi_prefix = 'wasm_memorytype_';
$ffi->type('opaque' => 'wasm_memorytype_t');

=head1 CONSTRUCTOR

=head2 new

 my $memorytype = Wasm::Wasmtime::MemoryType->new([
   $min,  # minumum number of pages
   $max   # maximum number of pages
 ]);

Creates a new memory type object.

=cut

$ffi->attach( new => ['uint32[2]'] => 'wasm_memorytype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(ref $_[0])
  {
    $ptr = $xsub->(shift);
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr => $ptr,
    owner => $owner,
  }, $class;
});

=head2 limits

 my $limits = $memorytype->limits;

Returns the minimum and maximum number of pages as an array reference.

=cut

$ffi->attach( limits => ['wasm_memorytype_t'] => 'uint32[2]' => sub {
  my($xsub, $self) = @_;
  my $limits = $xsub->($self->{ptr});
  $limits;
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_memorytype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
