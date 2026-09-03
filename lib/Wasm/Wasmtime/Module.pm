package Wasm::Wasmtime::Module;

use strict;
use warnings;
use 5.008004;
use Ref::Util qw( is_blessed_ref );
use FFI::Platypus::Buffer ();
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Engine;
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

$ffi_prefix = 'wasmtime_module_';
$ffi->load_custom_type('::PtrObject' => 'wasmtime_module_t' => __PACKAGE__);

# returns the raw wasm binary as a scalar (caller must keep it alive while
# passing its buffer to C)
sub _wasm_bytes
{
  if(@_ == 1)
  {
    return $_[0];
  }
  my $key = shift;
  if($key eq 'wat')
  {
    require Wasm::Wasmtime::Wat2Wasm;
    return Wasm::Wasmtime::Wat2Wasm::wat2wasm(shift);
  }
  elsif($key eq 'wasm')
  {
    return shift;
  }
  elsif($key eq 'file')
  {
    require Path::Tiny;
    my $path = Path::Tiny->new(shift);
    if($path->basename =~ /\.wat/)
    {
      require Wasm::Wasmtime::Wat2Wasm;
      return Wasm::Wasmtime::Wat2Wasm::wat2wasm($path->slurp_utf8);
    }
    else
    {
      return $path->slurp_raw;
    }
  }
  Carp::croak("unknown module source: $key");
}

sub _engine
{
  my $args = shift;
  my $first = $args->[0];
  if(defined $first && is_blessed_ref $first)
  {
    if($first->isa('Wasm::Wasmtime::Engine'))
    {
      shift @$args;
      return $first;
    }
    elsif($first->isa('Wasm::Wasmtime::Store'))
    {
      shift @$args;
      Carp::carp("Passing a Wasm::Wasmtime::Store into the module constructor is deprecated, please pass a Wasm::Wasmtime::Engine object instead");
      return $first->engine;
    }
  }
  return Wasm::Wasmtime::Engine->new;
}

=head1 CONSTRUCTORS

=head2 new

 my $module = Wasm::Wasmtime::Module->new(
   $engine,       # Wasm::Wasmtime::Engine (optional)
   wat => $wat,   # WebAssembly Text
 );
 my $module = Wasm::Wasmtime::Module->new(
   $engine,       # Wasm::Wasmtime::Engine (optional)
   wasm => $wasm, # WebAssembly binary
 );
 my $module = Wasm::Wasmtime::Module->new(
   $engine,       # Wasm::Wasmtime::Engine (optional)
   file => $path, # Filename containing WebAssembly binary (.wasm) or WebAssembly Text (.wat)
 );

Create a new WebAssembly module object.  You must provide either WebAssembly Text (WAT), WebAssembly binary (Wasm), or a
filename of a file that contains WebAssembly binary (Wasm) or text (Wat).  If the optional L<Wasm::Wasmtime::Engine> object
is not provided one will be created for you.  A L<Wasm::Wasmtime::Store> may be passed instead of an engine, in which case
its engine is used.

=cut

$ffi->attach( [ wasmtime_module_new => 'new' ] => ['wasm_engine_t', 'opaque', 'size_t', 'opaque*'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $engine = _engine(\@_);
  my $data = _wasm_bytes(@_);
  my($ptr_in, $len) = FFI::Platypus::Buffer::scalar_to_buffer($data);
  my $ptr;
  if(my $error = $xsub->($engine, $ptr_in, $len, \$ptr))
  {
    Carp::croak("error creating module: " . $error->message);
  }
  bless { ptr => $ptr, engine => $engine }, $class;
});

=head2 deserialize

 my $module = Wasm::Wasmtime::Module->deserialize(
   $engine,       # Wasm::Wasmtime::Engine (optional)
   $serialized,   # serialized module
 );

Build a module from serialized data.  The serialized data can be gotten from the C<serialize> method documented below.

=cut

$ffi->attach( [ wasmtime_module_deserialize => 'deserialize' ] => ['wasm_engine_t', 'opaque', 'size_t', 'opaque*'] => 'wasmtime_error_t' => sub {
  my $xsub  = shift;
  my $class = shift;
  my $engine = _engine(\@_);
  my $serialized = shift;
  my($ptr_in, $len) = FFI::Platypus::Buffer::scalar_to_buffer($serialized);
  my $ptr;
  if(my $error = $xsub->($engine, $ptr_in, $len, \$ptr))
  {
    Carp::croak("error creating module: " . $error->message);
  }
  bless { ptr => $ptr, engine => $engine }, $class;
});

=head1 METHODS

=head2 validate

 my($ok, $message) = Wasm::Wasmtime::Module->validate(
   $engine,       # Wasm::Wasmtime::Engine (optional)
   wat => $wat,   # or wasm => $wasm, or file => $path
 );

Takes the same arguments as C<new>, but validates the module without creating a module object.

=cut

$ffi->attach( [ wasmtime_module_validate => 'validate' ] => ['wasm_engine_t', 'opaque', 'size_t'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $engine = _engine(\@_);
  my $data = _wasm_bytes(@_);
  my($ptr_in, $len) = FFI::Platypus::Buffer::scalar_to_buffer($data);
  my $error = $xsub->($engine, $ptr_in, $len);
  wantarray  ## no critic (Community::Wantarray)
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

$ffi->attach( [ wasmtime_module_exports => '_exports' ]=> [ 'wasmtime_module_t', 'wasm_exporttype_vec_t*' ] => sub {
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

$ffi->attach( [ wasmtime_module_imports => '_imports' ] => [ 'wasmtime_module_t', 'wasm_importtype_vec_t*' ] => sub {
  my($xsub, $self) = @_;
  my $imports = Wasm::Wasmtime::ImportTypeVec->new;
  $xsub->($self, $imports);
  $imports->to_list;
});

=head2 serialize

 my $serialized = $module->serialize;

This function serializes compiled module artifacts as blob data.  This data can be reconstituted with the
C<deserialize> constructor method documented above.

=cut

$ffi->attach( [ 'wasmtime_module_serialize' => 'serialize' ] => [ 'wasmtime_module_t', 'wasm_byte_vec_t*' ] => 'wasmtime_error_t' => sub {
  my($xsub, $self) = @_;
  my $s = Wasm::Wasmtime::ByteVec->new;
  if(my $error = $xsub->($self, $s))
  {
    Carp::croak("error serializing module: " . $error->message);
  }
  else
  {
    my $s2 = $s->get;
    $s->delete;
    return $s2;
  }
});

=head2 engine

 my $engine = $module->engine;

Returns the L<Wasm::Wasmtime::Engine> object used by this module.

=cut

sub engine { shift->{engine} }

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

_generate_destroy('wasmtime_module_delete');

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
