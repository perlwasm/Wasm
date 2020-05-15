package Wasm::Wasmtime::Module;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Module::Exports;
use Wasm::Wasmtime::Module::Imports;
use Wasm::Wasmtime::ImportType;
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
$ffi->load_custom_type('::PtrObject' => 'wasm_module_t' => __PACKAGE__);

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
      my $path = Path::Tiny->new(shift);
      if($path->basename =~ /\.wat/)
      {
        $data = Wasm::Wasmtime::Wat2Wasm::wat2wasm($path->slurp_utf8);
        $wasm = Wasm::Wasmtime::ByteVec->new($data);
      }
      else
      {
        $data = $path->slurp_raw;
        $wasm = Wasm::Wasmtime::ByteVec->new($data);
      }
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
   file => $path, # Filename containing WebAssembly binary (.wasm) or WebAssembly Text (.wat)
 );
 my $module = Wasm::Wasmtime::Module->new(
   wat => $wat,   # WebAssembly Text
 );
 my $module = Wasm::Wasmtime::Module->new(
   wasm => $wasm, # WebAssembly binary
 );
 my $module = Wasm::Wasmtime::Module->new(
   file => $path, # Filename containing WebAssembly binary (.wasm) or WebAssembly Text (.wat)
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

$ffi->attach( [ wasmtime_module_new => 'new' ] => ['wasm_store_t', 'wasm_byte_vec_t*', 'opaque*'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($store, $wasm, $data) = _args(@_);
  my $ptr;
  if(my $error = $xsub->($store, $$wasm, \$ptr))
  {
    Carp::croak("error creating module: " . $error->message);
  }
  bless { ptr => $ptr, store => $store }, $class;
});

$ffi->attach( [ wasmtime_module_validate => 'validate' ] => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($store, $wasm, $data) = _args(@_);
  my $error = $xsub->($store, $$wasm);
  wantarray  ## no critic (Freenode::Wantarray)
    ? $error ? (0, $error->message) : (1, '')
    : $error ? 0 : 1;
});

=head2 exports

 my $exports = $module->exports;

Returns a L<Wasm::Wasmtime::Module::Exports> object that can be used to query the module exports.

=cut

sub exports
{
  Wasm::Wasmtime::Module::Exports->new(shift);
}

$ffi->attach( [ exports => '_exports' ]=> [ 'wasm_module_t', 'wasm_exporttype_vec_t*' ] => sub {
  my($xsub, $self) = @_;
  my $exports = Wasm::Wasmtime::ExportTypeVec->new;
  $xsub->($self, $exports);
  $exports->to_list;
});

=head2 imports

 my $imports = $module->imports;

Returns a list of L<Wasm::Wasmtime::ImportType> objects for the objects imported by the WebAssembly module.

=cut

sub imports
{
  Wasm::Wasmtime::Module::Imports->new(shift);
}

$ffi->attach( [ imports => '_imports' ] => [ 'wasm_module_t', 'wasm_importtype_vec_t*' ] => sub {
  my($xsub, $self) = @_;
  my $imports = Wasm::Wasmtime::ImportTypeVec->new;
  $xsub->($self, $imports);
  $imports->to_list;
});

=head2 store

 my $store = $module->store;

Returns the L<Wasm::Wasmtime::Store> object used by this module.

=cut

sub store { shift->{store} }

=head2 to_string

 my $string = $module->to_string;

Converts the module imports and exports into a string for diagnostics.

=cut

sub to_string
{
  my($self) = @_;
  my @externs = (@{ $self->imports }, @{ $self->exports });
  return "(module)\n" unless @externs;
  my $string = "(module\n";
  foreach my $extern (@externs)
  {
    $string .= "  " . $extern->to_string . "\n";
  }
  $string .= ")\n";
}

_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
