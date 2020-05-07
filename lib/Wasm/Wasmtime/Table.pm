package Wasm::Wasmtime::Table;

use strict;
use warnings;
use base qw( Wasm::Wasmtime::Extern );
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::TableType;
use constant is_table => 1;
use constant kind => 'table';

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
$ffi->load_custom_type('::PtrObject' => 'wasm_table_t' => __PACKAGE__);

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
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});

=head2 size

 my $size = $table->size;

Returns the size of the table.

=cut

$ffi->attach( size => ['wasm_table_t'] => 'uint32' );

__PACKAGE__->_cast(2);
_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
