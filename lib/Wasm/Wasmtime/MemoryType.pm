package Wasm::Wasmtime::MemoryType;

use strict;
use warnings;
use 5.008004;
use base qw( Wasm::Wasmtime::ExternType );
use Ref::Util qw( is_ref is_plain_arrayref is_plain_hashref );
use Wasm::Wasmtime::FFI;
use Carp ();
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
maximum number of pages, whether the memory is a 64-bit (memory64) memory,
whether it is shared, and its page size.

=cut

$ffi_prefix = 'wasm_memorytype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_memorytype_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $memorytype = Wasm::Wasmtime::MemoryType->new([
   $min,  # minimum number of pages
   $max   # maximum number of pages (optional)
 ]);

 my $memorytype = Wasm::Wasmtime::MemoryType->new({
   minimum        => $min,     # minimum number of pages (required)
   maximum        => $max,     # maximum number of pages (optional)
   is64           => $bool,    # 64-bit (memory64) memory (default: false)
   shared         => $bool,    # shared memory              (default: false)
   page_size_log2 => $log2,    # log2 of the page size in bytes (default: 16)
 });

Creates a new memory type object.

The array reference form always creates a 32-bit, non-shared memory type with
the default 64KiB page size.  Use the hash reference form to opt into the
memory64, shared-memory, or custom-page-sizes proposals.

=cut

my $new64 = $ffi->function( 'wasmtime_memorytype_new' => ['uint64','bool','uint64','bool','bool','uint8','opaque*'] => 'wasmtime_error_t' )->sub_ref;

$ffi->attach( new => ['uint32[2]'] => 'wasm_memorytype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(is_plain_hashref $_[0])
  {
    my $opt = shift;
    my $min = defined $opt->{minimum} ? $opt->{minimum} : $opt->{min};
    Carp::croak("no minimum in limit") unless defined $min;
    my $max = defined $opt->{maximum} ? $opt->{maximum} : $opt->{max};
    my $max_present = defined $max ? 1 : 0;
    $max = 0 unless defined $max;
    my $is64   = $opt->{is64}   ? 1 : 0;
    my $shared = $opt->{shared} ? 1 : 0;
    my $page_size_log2 = defined $opt->{page_size_log2} ? $opt->{page_size_log2} : 16;
    my $ptr;
    if(my $error = $new64->($min, $max_present, $max, $is64, $shared, $page_size_log2, \$ptr))
    {
      Carp::croak($error->message);
    }
    return bless { ptr => $ptr, owner => undef }, $class;
  }
  elsif(is_ref $_[0])
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

=head2 minimum

 my $min = $memorytype->minimum;

Returns the minimum size, in pages, of the memory type.

=cut

$ffi->attach( [ wasmtime_memorytype_minimum => 'minimum' ] => ['wasm_memorytype_t'] => 'uint64' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 maximum

 my $max = $memorytype->maximum;

Returns the maximum size, in pages, of the memory type, or C<undef> if the
memory type has no maximum.

=cut

$ffi->attach( [ wasmtime_memorytype_maximum => 'maximum' ] => ['wasm_memorytype_t','uint64*'] => 'bool' => sub {
  my($xsub, $self) = @_;
  my $max = 0;
  $xsub->($self, \$max) ? $max : undef;
});

=head2 limits

 my $limits = $memorytype->limits;

Returns the minimum and maximum number of pages as an array reference.  If the
memory type has no maximum then C<0xffffffff> is returned as the maximum.

=cut

sub limits
{
  my($self) = @_;
  my $max = $self->maximum;
  [ $self->minimum, defined $max ? $max : 0xffffffff ];
}

=head2 is64

 my $bool = $memorytype->is64;

Returns true if this is a 64-bit (memory64) memory type.

=cut

$ffi->attach( [ wasmtime_memorytype_is64 => 'is64' ] => ['wasm_memorytype_t'] => 'bool' => sub {
  my($xsub, $self) = @_;
  $xsub->($self) ? 1 : 0;
});

=head2 is_shared

 my $bool = $memorytype->is_shared;

Returns true if this is a shared memory type.

=cut

$ffi->attach( [ wasmtime_memorytype_isshared => 'is_shared' ] => ['wasm_memorytype_t'] => 'bool' => sub {
  my($xsub, $self) = @_;
  $xsub->($self) ? 1 : 0;
});

=head2 page_size

 my $bytes = $memorytype->page_size;

Returns the page size, in bytes, of this memory type.  This is C<65536>
(64KiB) unless the custom-page-sizes proposal is in use.

=cut

$ffi->attach( [ wasmtime_memorytype_page_size => 'page_size' ] => ['wasm_memorytype_t'] => 'uint64' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 page_size_log2

 my $log2 = $memorytype->page_size_log2;

Returns the base-2 logarithm of this memory type's page size in bytes (C<16>
for the default 64KiB page size).

=cut

$ffi->attach( [ wasmtime_memorytype_page_size_log2 => 'page_size_log2' ] => ['wasm_memorytype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 to_string

 my $string = $memorytype->to_string;

Converts the type into a string for diagnostics.

=cut

sub to_string
{
  my($self) = @_;
  my($min, $max) = @{ $self->limits };
  my $string = "$min";
  $string .= " $max" if $max != 0xffffffff;
  $string .= " shared" if $self->is_shared;
  $string .= " i64" if $self->is64;
  return $string;
}

__PACKAGE__->_cast(3);
_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
