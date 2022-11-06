package Wasm::Wasmtime::Module;

use strict;
use warnings;
use 5.008004;
use Ref::Util qw( is_blessed_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Engine;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::ModuleType::Exports;
use Wasm::Wasmtime::ModuleType::Imports;
use Wasm::Wasmtime::ModuleType;
use Wasm::Wasmtime::ImportType;
use Wasm::Wasmtime::ExportType;
use Ref::Util qw( is_blessed_ref );
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

$ffi->load_custom_type('::PtrObject' => 'wasm_module_t' => __PACKAGE__);

if(_ver ne '0.27.0')
{
  $ffi_prefix = 'wasmtime_module_';

  require FFI::Platypus::Buffer;
  *_args = sub
  {
    my $data;
    if(@_ == 1)
    {
      $data = shift;
    }
    else
    {
      my $key = shift;
      if($key eq 'wat')
      {
        require Wasm::Wasmtime::Wat2Wasm;
        $data = Wasm::Wasmtime::Wat2Wasm::wat2wasm(shift);
      }
      elsif($key eq 'wasm')
      {
        $data = shift;
      }
      elsif($key eq 'file')
      {
        require Wasm::Wasmtime::Wat2Wasm;
        require Path::Tiny;
        my $path = Path::Tiny->new(shift);
        if($path->basename =~ /\.wat/)
        {
          $data = Wasm::Wasmtime::Wat2Wasm::wat2wasm($path->slurp_utf8);
        }
        else
        {
          $data = $path->slurp_raw;
        }
      }
    }

    (FFI::Platypus::Buffer::scalar_to_buffer($data), \$data);  # need to return the data in order to keep it in scope
  };
}
else
{
  $ffi_prefix = 'wasm_module_';

  *_args = sub
  {
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
    (\$wasm, \$data);
  };
}

=head1 CONSTRUCTORS

=head2 new

 my $module = Wasm::Wasmtime::Module->new(
   $engine,       # Wasm::Wasmtime::Engine
   wat => $wat,   # WebAssembly Text
 );
 my $module = Wasm::Wasmtime::Module->new(
   $engine,       # Wasm::Wasmtime::Engine
   wasm => $wasm, # WebAssembly binary
 );
 my $module = Wasm::Wasmtime::Module->new(
   $engine,       # Wasm::Wasmtime::Engine
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
filename of a file that contains WebAssembly binary (Wasm).  If the optional L<Wasm::Wasmtime::Engine> object is not provided
one will be created for you.

[Deprecated]

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

You can provide a L<Wasm::Wasmtime::Store> instance instead of a L<Wasm::Wasmtime::Engine>.  Although the store
instance is no longer required internally to create a module instance, the engine object which is needed can
be found from the store.  This form will be removed in a future version.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( new => ['wasm_engine_t', 'opaque', 'size_t', 'opaque*'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $class = shift;
    my $store;
    my $engine;
    if(defined $_[0] && is_blessed_ref $_[0])
    {
      if($_[0]->isa('Wasm::Wasmtime::Engine'))
      {
        $engine = shift;
      }
      elsif($_[0]->isa('Wasm::Wasmtime::Store'))
      {
        Carp::carp("Passing a Wasm::Wasmtime::Store into the module constructor is deprecated, please pass a Wasm::Wasmtime::Engine object instead");
        $store = shift;
        $engine = $store->engine;
      }
    }
    $engine ||= Wasm::Wasmtime::Engine->new;
    my($wasm_ptr, $wasm_len, $data) = _args(@_);
    my $module_ptr;
    if(my $error = $xsub->($engine, $wasm_ptr, $wasm_len, \$module_ptr))
    {
      Carp::croak("error creating module: " . $error->message);
    }
    bless { ptr => $module_ptr, engine => $engine, store => $store }, $class;
  });
}
else
{
  $ffi->attach( [ wasmtime_module_new => 'new' ] => ['wasm_engine_t', 'wasm_byte_vec_t*', 'opaque*'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $class = shift;
    my $store;
    my $engine;
    if(defined $_[0] && is_blessed_ref $_[0])
    {
      if($_[0]->isa('Wasm::Wasmtime::Engine'))
      {
        $engine = shift;
      }
      elsif($_[0]->isa('Wasm::Wasmtime::Store'))
      {
        Carp::carp("Passing a Wasm::Wasmtime::Store into the module constructor is deprecated, please pass a Wasm::Wasmtime::Engine object instead");
        $store = shift;
        $engine = $store->engine;
      }
    }
    $engine ||= Wasm::Wasmtime::Engine->new;
    my($wasm, $data) = _args(@_);
    my $ptr;
    if(my $error = $xsub->($engine, $$wasm, \$ptr))
    {
      Carp::croak("error creating module: " . $error->message);
    }
    bless { ptr => $ptr, engine => $engine, store => $store }, $class;
  });
}

=head2 deserialize

 my $module = Wasm::Wasmtime::Module->deserialize(
   $engine,       # Wasm::Wasmtime::Engine
   $serialized,   # serialized module
 );
 my $module = Wasm::Wasmtime::Module->deserialize(
   $serialized,   # serialized module
 );

Build a module from serialized data.  The serialized data can be gotten from the C<serialize> method documented below.

=cut

if(_ver ne '0.27.0')
{
  require FFI::Platypus::Buffer;
  $ffi->attach( deserialize => ['wasm_engine_t', 'opaque', 'size_t', 'opaque*'] => 'wasmtime_error_t' => sub {
    my $xsub  = shift;
    my $class = shift;
    my $engine;
    $engine = defined $_[0] && is_blessed_ref $_[0] && $_[0]->isa('Wasm::Wasmtime::Engine') ? shift : Wasm::Wasmtime::Engine->new;
    my($serialized_ptr, $serialized_len) = FFI::Platypus::Buffer::scalar_to_buffer($_[0]);
    my $module_ptr;
    if(my $error = $xsub->($engine, $serialized_ptr, $serialized_len, \$module_ptr))
    {
      Carp::croak("error creating module: " . $error->message);
    }
    bless { ptr => $module_ptr, store => undef, engine => $engine }, $class;
  });
}
else
{
  $ffi->attach( [ wasmtime_module_deserialize => 'deserialize' ] => ['wasm_engine_t', 'wasm_byte_vec_t*', 'opaque*'] => 'wasmtime_error_t' => sub {
    my $xsub  = shift;
    my $class = shift;
    my $engine;
    $engine = defined $_[0] && is_blessed_ref $_[0] && $_[0]->isa('Wasm::Wasmtime::Engine') ? shift : Wasm::Wasmtime::Engine->new;
    my $serialized = Wasm::Wasmtime::ByteVec->new($_[0]);
    my $ptr;
    if(my $error = $xsub->($engine, $serialized, \$ptr))
    {
      Carp::croak("error creating module: " . $error->message);
    }
    bless { ptr => $ptr, store => undef, engine => $engine }, $class;
  });
}

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

if(_ver ne '0.27.0')
{
  $ffi->attach( validate => ['wasm_engine_t', 'opaque', 'size_t'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $class = shift;
    # TODO: we should deprecate passing a store into this
    my $store = defined $_[0] && ref($_[0]) eq 'Wasm::Wasmtime::Store' ? shift : Wasm::Wasmtime::Store->new;
    my($ptr, $len, $data) = _args(@_);
    my $error = $xsub->($store->engine, $ptr, $len);
    wantarray  ## no critic (Community::Wantarray)
      ? $error ? (0, $error->message) : (1, '')
      : $error ? 0 : 1;
  });
}
else
{
  $ffi->attach( [ wasmtime_module_validate => 'validate' ] => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $class = shift;
    my $store = defined $_[0] && ref($_[0]) eq 'Wasm::Wasmtime::Store' ? shift : Wasm::Wasmtime::Store->new;
    my($wasm, $data) = _args(@_);
    my $error = $xsub->($store, $$wasm);
    wantarray  ## no critic (Community::Wantarray)
      ? $error ? (0, $error->message) : (1, '')
      : $error ? 0 : 1;
  });
}

=head2 type

 my $type = $module->type;

Returns a L<Wasm::Wasmtime::Module::Type> instance that can be used to get the module exports and
imports.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( type => ['wasm_module_t'] => 'wasmtime_moduletype_t');
}
else
{
  *type = sub {
    my($self) = @_;
    bless { module => $self }, 'Wasm::Wasmtime::ModuleType';
  };
}

=head2 exports

[deprecated; please use $module->type->exports instead]

 my $exports = $module->exports;

Returns a L<Wasm::Wasmtime::ModuleType::Exports> object that can be used to query the module exports.

=cut

sub exports
{
  my($self) = @_;
  Carp::carp("The exports method on Wasm::Wasmtime::Module is deprecated, please use \$module->type->exports instead");
  $self->type->exports;
}

if(_ver eq '0.27.0')
{
  $ffi->attach( [ exports => '_exports' ]=> [ 'wasm_module_t', 'wasm_exporttype_vec_t*' ] => sub {
    my($xsub, $self) = @_;
    my $exports = Wasm::Wasmtime::ExportTypeVec->new;
    $xsub->($self, $exports);
    $exports->to_list;
  });
}

=head2 imports

[deprecated; please use $module->type->imports instead]

 my $imports = $module->imports;

Returns a L<Wasm::Wasmtime::ModuleType::Imports> for the objects imported by the WebAssembly module.

=cut

sub imports
{
  my($self) = @_;
  Carp::carp("The imports method on Wasm::Wasmtime::Module is deprecated, please use \$module->type->imports instead");
  $self->type->imports;
}

if(_ver eq '0.27.0')
{
  $ffi->attach( [ imports => '_imports' ] => [ 'wasm_module_t', 'wasm_importtype_vec_t*' ] => sub {
    my($xsub, $self) = @_;
    my $imports = Wasm::Wasmtime::ImportTypeVec->new;
    $xsub->($self, $imports);
    $imports->to_list;
  });
}

=head2 serialize

 my $serialized = $module->serialize;

This function serializes compiled module artifacts as blob data.  This data can be reconstituted with the
C<deserialize> constructor method documented above.

=cut

# TODO remove prefix when bump to 0.28.0
$ffi->attach( [ wasmtime_module_serialize => 'serialize' ] => [ 'wasm_module_t', 'wasm_byte_vec_t*' ] => 'wasmtime_error_t' => sub {
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
  my @externs = (@{ $self->type->imports }, @{ $self->type->exports });
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

