package Wasm::Wasmtime::Module;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::ExportType;
use Carp ();

# ABSTRACT: Wasmtime module class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/module.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly module.

=cut

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

=head1 CONSTRUCTOR

=head2 new

 my $module = Wasm::Wasmtime::Module->new(
   $store,        # Wasm::Wasmtime::Store
   wat => $wat,   # WebAssembly Text
 );
 my $module = Wasm::Wasmtime::Module->new(
   $store,        # Wasm::Wasmtime::Store
   wasm => $wasm, # WebAssembly binary
 );
 my $module = Wasm::Wasmtime::Module->new(
   $store,        # Wasm::Wasmtime::Store
   file => $path, # Filename containing WebAssembly binary (.wasm)
 );
 my $module = Wasm::Wasmtime::Module->new(
   wat => $wat,   # WebAssembly Text
 );
 my $module = Wasm::Wasmtime::Module->new(
   wasm => $wasm, # WebAssembly binary
 );
 my $module = Wasm::Wasmtime::Module->new(
   file => $path, # Filename containing WebAssembly binary (.wasm)
 );

Create a new WebAssembly module object.  You must provide either WebAssembly Text (WAT), WebAssembly binary (Wasm), or a
filename of a file that contains WebAssembly binary (Wasm).  If the optional L<Wasm::Wasmtime::Store> object is not provided
one will be created for you.

=head1 METHODS

=head2 validate

 my($ok, $mssage) = Wasm::Wasmtime::Module->validate(
   $store,        # Wasm::Wasmtime::Store
   wat => $wat,   # WebAssembly Text
 );
 my($ok, $mssage) = Wasm::Wasmtime::Module->validate(
   $store,        # Wasm::Wasmtime::Store
   wasm => $wasm, # WebAssembly binary
 );
 my($ok, $mssage) = Wasm::Wasmtime::Module->validate(
   $store,        # Wasm::Wasmtime::Store
   file => $path, # Filename containing WebAssembly binary (.wasm)
 );
 my($ok, $mssage) = Wasm::Wasmtime::Module->validate(
   wat => $wat,   # WebAssembly Text
 );
 my($ok, $mssage) = Wasm::Wasmtime::Module->validate(
   wasm => $wasm, # WebAssembly binary
 );
 my($ok, $mssage) = Wasm::Wasmtime::Module->validate(
   file => $path, # Filename containing WebAssembly binary (.wasm)
 );

Takes the same arguments as C<new>, but validates the module without creating a module object.  Returns C<$ok>,
which is true if the WebAssembly is valid, and false otherwise.  For invalid WebAssembly C<$message> may contain
a useful diagnostic for why it was invalid.

=cut

if(Wasm::Wasmtime::Error->can('new'))
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

=head2 exports

 my @exporttypes = $module->exports;

Returns a list of L<Wasm::Wasmtime::ExportType> objects for the objects exported by the WebAssembly module.

=cut

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

=head2 store

 my $store = $module->store;

Returns the L<Wasm::Wasmtime::Store> object used by this module.

=cut

sub store { shift->{store} }

=head2 get_export

 my $exporttype = $module->get_export($name);

Returns the L<Wasm::Wasmtime::ExportType> with the given C<$name> as exported by the WebAssembly module.
If no such export exists, then C<undef> is returned.

=cut

sub get_export
{
  my($self, $name) = @_;
  $self->{exports} ||= do {
    my @exports = $self->exports;
    my %exports;
    foreach my $export (@exports)
    {
      $exports{$export->name} = $export->type;
    }
    \%exports;
  };
  $self->{exports}->{$name};
}

1;
