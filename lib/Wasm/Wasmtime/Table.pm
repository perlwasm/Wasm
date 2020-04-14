package Wasm::Wasmtime::Table;

use strict;
use warnings;
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::TableType;

# ABSTRACT: Wasmtime table class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/table.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly table object.

=cut

$ffi_prefix = 'wasm_table_';
$ffi->type('opaque' => 'wasm_table_t');

sub new
{
  # TODO: add wasm_table_new for standalone support
  # TODO: add wasm_table_set
  # TODO: add wasm_table_get
  # TODO: add wasm_table_grow
  my($class, $ptr, $owner) = @_;
  bless {
    ptr => $ptr,
    owner => $owner,
  }, $class;
}

=head1 METHODS

=head2 type

 my $tabletype = $table->type;

Returns the L<Wasm::Wasmtime::TableType> object for this table object.

=cut

$ffi->attach( type => ['wasm_table_t'] => 'wasm_tabletype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::TableType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});

=head2 size

 my $size = $table->size;

Returns the size of the table.

=cut

$ffi->attach( size => ['wasm_table_t'] => 'uint32' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

=head2 as_extern

 my $extern = $table->as_extern;

Returns the L<Wasm::Wasmtime::Extern> for this table object.

=cut

# actually returns a wasm_extern_t, but recursion
$ffi->attach( as_extern => ['wasm_table_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::Extern;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::Extern->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_table_t'] => sub {
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

