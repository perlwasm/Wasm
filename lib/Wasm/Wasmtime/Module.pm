package Wasm::Wasmtime::Module;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::ExportType;

# ABSTRACT: Wasmtime module class
# VERSION

$ffi->mangler(sub { "wasm_module_$_[0]" });
$ffi->type('opaque' => 'wasm_module_t');

$ffi->attach( new => ['wasm_store_t','wasm_byte_vec_t*'] => 'wasm_module_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $store = defined $_[0] && ref($_[0]) eq 'Wasm::Wasmtime::Store' ? shift : Wasm::Wasmtime::Store->new;
  my $wasm;
  my $data;
  if(@_ == 1)
  {
    $wasm = Wasm::Wasmtime::ByteVec->new(shift);
  }
  else
  {
    my $key = shift;
    if($key eq 'wat')
    {
      require Wasm::Wasmtime::Wat2Wasm;
      $data = Wasm::Wasmtime::Wat2Wasm::wat2wasm(shift);
      $wasm = Wasm::Wasmtime::ByteVec->new($data);
    }
    elsif($key eq 'wasm')
    {
      $wasm = Wasm::Wasmtime::ByteVec->new(shift);
    }
    elsif($key eq 'file')
    {
      require Wasm::Wasmtime::Wat2Wasm;
      require Path::Tiny;
      $data = Wasm::Wasmtime::Wat2Wasm::wat2wasm(Path::Tiny->new(shift)->slurp_utf8);
      $wasm = Wasm::Wasmtime::ByteVec->new($data);
    }
  }
  bless {
    ptr   => $xsub->($store->{ptr}, $wasm),
    store => $store,
  }, $class;
});

$ffi->attach( validate => ['wasm_store_t','wasm_byte_vec_t*'] => 'bool' => sub {
  my $xsub = shift;
  my $class = shift;
  my $store = defined $_[0] && ref($_[0]) eq 'Wasm::Wasmtime::Store' ? shift : Wasm::Wasmtime::Store->new;
  my $wasm = Wasm::Wasmtime::ByteVec->new($_[0]);
  $xsub->($store->{ptr}, $wasm);
});

$ffi->attach( exports => [ 'wasm_module_t', 'wasm_exporttype_vec_t*' ] => sub {
  my($xsub, $self) = @_;
  my $exports = Wasm::Wasmtime::ExportTypeVec->new;
  $xsub->($self->{ptr}, $exports);
  my $size = $exports->size;
  my $ptrs = $ffi->cast('opaque', "wasm_exporttype_t[$size]", $exports->data);
  map { Wasm::Wasmtime::ExportType->new($_, $exports) } @$ptrs;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_module_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

=head1 METHODS

=head2 store

=cut

sub store { shift->{store} }

1;
