package Wasm::Wasmtime::MemoryType;

use strict;
use warnings;
use base qw( Wasm::Wasmtime::ExternType );
use Ref::Util qw( is_ref is_plain_arrayref );
use Wasm::Wasmtime::FFI;
use constant is_memorytype => 1;
use constant kind => 'memorytype';

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
$ffi->load_custom_type('::PtrObject' => 'wasm_memorytype_t' => __PACKAGE__);

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
  if(is_ref $_[0])
  {
    my $limit = shift;
    Carp::croak("bad limits") unless is_plain_arrayref($limit);
    Carp::croak("no minumum in limit") unless defined $limit->[0];
    $limit->[1] = 0xffffffff unless defined $limit->[1];
    return $xsub->($limit);
  }
  else
  {
    my ($ptr, $owner) = @_;
    return bless {
      ptr => $ptr,
      owner => $owner,
    }, $class;
  }
});

=head2 limits

 my $limits = $memorytype->limits;

Returns the minimum and maximum number of pages as an array reference.

=cut

$ffi->attach( limits => ['wasm_memorytype_t'] => 'uint32[2]' => sub {
  my($xsub, $self) = @_;
  my $limits = $xsub->($self);
  $limits;
});

__PACKAGE__->_cast(3);
_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

