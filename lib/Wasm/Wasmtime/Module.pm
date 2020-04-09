package Wasm::Wasmtime::Module;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::ExportType;
use Carp ();

# ABSTRACT: Wasmtime module class
# VERSION

$ffi_prefix = 'wasm_module_';
$ffi->type('opaque' => 'wasm_module_t');

sub _args
{
  my $store = defined $_[0] && ref($_[0]) eq 'Wasm::Wasmtime::Store' ? shift : Wasm::Wasmtime::Store->new;
  my $wasm;
  my $data;
  if(@_ == 1)
  {
    $data = shift;
    $wasm = Wasm::Wasmtime::ByteVec->new($data);
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
      $data = shift;
      $wasm = Wasm::Wasmtime::ByteVec->new($data);
    }
    elsif($key eq 'file')
    {
      require Wasm::Wasmtime::Wat2Wasm;
      require Path::Tiny;
      $data = Wasm::Wasmtime::Wat2Wasm::wat2wasm(Path::Tiny->new(shift)->slurp_utf8);
      $wasm = Wasm::Wasmtime::ByteVec->new($data);
    }
  }
  ($store, \$wasm, \$data);
}

if($ffi->find_symbol('wasmtime_error_message'))
{

  $ffi->attach( [ wasmtime_module_new => 'new' ] => ['wasm_store_t', 'wasm_byte_vec_t*', 'wasm_module_t*'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $class = shift;
    my($store, $wasm, $data) = _args(@_);
    my $ptr;
    if(my $error = $xsub->($store->{ptr}, $$wasm, \$ptr))
    {
      Carp::croak("error creating module: " . $error->message);
    }
    bless { ptr => $ptr, store => $store }, $class;
  });

  $ffi->attach( [ wasmtime_module_validate => 'validate' ] => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $class = shift;
    my($store, $wasm, $data) = _args(@_);
    my $error = $xsub->($store->{ptr}, $$wasm);
    wantarray  ## no critic (Freenode::Wantarray)
      ? $error ? (0, $error->message) : (1, '')
      : $error ? 0 : 1;
  });
}
else
{

  $ffi->attach( new => ['wasm_store_t','wasm_byte_vec_t*'] => 'wasm_module_t' => sub {
    my $xsub = shift;
    my $class = shift;
    my($store, $wasm, $data) = _args(@_);
    my $ptr = $xsub->($store->{ptr}, $$wasm);
    Carp::croak("error creating module") unless $ptr;
    bless {
      ptr   => $ptr,
      store => $store,
    }, $class;
  });

  $ffi->attach( validate => ['wasm_store_t','wasm_byte_vec_t*'] => 'bool' => sub {
    my $xsub = shift;
    my $class = shift;
    my($store, $wasm, $data) = _args(@_);
    my $ok = $xsub->($store->{ptr}, $$wasm);
    wantarray  ## no critic (Freenode::Wantarray)
      ? $ok ? (1, '') : (0, 'unknown error')
      : $ok ? 1 : 0;
  });

}

$ffi->attach( exports => [ 'wasm_module_t', 'wasm_exporttype_vec_t*' ] => sub {
  my($xsub, $self) = @_;
  my $exports = Wasm::Wasmtime::ExportTypeVec->new;
  $xsub->($self->{ptr}, $exports);
  $exports->to_list;
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
