package Wasm::Wasmtime::Instance;

use strict;
use warnings;
use 5.008004;
use FFI::C::Util qw( addressof );
use FFI::Platypus::Buffer ();
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::Memory;
use Wasm::Wasmtime::Trap;
use Wasm::Wasmtime::Instance::Exports;
use Ref::Util qw( is_ref is_blessed_ref is_plain_coderef is_plain_scalarref );
use Carp ();

# ABSTRACT: Wasmtime instance class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/instance.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents an instance of a WebAssembly module L<Wasm::Wasmtime::Module>.

=cut

$ffi_prefix = 'wasmtime_instance_';

=head1 CONSTRUCTOR

=head2 new

 my $instance = Wasm::Wasmtime::Instance->new(
   $module,    # Wasm::Wasmtime::Module
   $store      # Wasm::Wasmtime::Store
 );
 my $instance = Wasm::Wasmtime::Instance->new(
   $module,    # Wasm::Wasmtime::Module
   $store,     # Wasm::Wasmtime::Store
   \@imports,  # array reference of Wasm::Wasmtime::Extern (or shortcuts)
 );

Create a new instance.  C<@imports> should match the imports specified by
C<$module>.  Shortcuts: a plain code reference for a function import, a scalar
reference or C<undef> for a memory import.

=cut

sub _cast_import
{
  my($ii, $mi, $store, $keep, $slot) = @_;

  if(is_blessed_ref($ii) && $ii->isa('Wasm::Wasmtime::Extern'))
  {
    return $ii->_fill_extern($slot);
  }
  elsif(is_plain_coderef($ii))
  {
    if($mi->type->kind eq 'functype')
    {
      my $f = Wasm::Wasmtime::Func->new($store, $mi->type, $ii);
      push @$keep, $f;
      return $f->_fill_extern($slot);
    }
  }
  elsif(is_plain_scalarref($ii) || !defined $ii)
  {
    if($mi->type->kind eq 'memorytype')
    {
      my $m = Wasm::Wasmtime::Memory->new($store, $mi->type);
      $$ii = $m if is_plain_scalarref($ii);
      push @$keep, $m;
      return $m->_fill_extern($slot);
    }
  }
  Carp::croak("Non-extern object as import");
}

$ffi->attach( [ wasmtime_instance_new => 'new' ] => ['opaque','wasmtime_module_t','opaque','size_t','wasmtime_instance_t','opaque*'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $module = shift;
  my $store = is_blessed_ref($_[0]) && $_[0]->isa('Wasm::Wasmtime::Store')
    ? shift
    : Carp::croak('Wasm::Wasmtime::Instance->new requires a Wasm::Wasmtime::Store object');

  my($imports) = @_;
  $imports ||= [];
  Carp::confess("imports is not an array reference") unless ref($imports) eq 'ARRAY';

  my @mi = @{ $module->imports };
  Carp::croak("Got @{[ scalar @$imports ]} imports, but expected @{[ scalar @mi ]}")
    if @$imports != @mi;

  my @keep;
  my $array;
  if(@$imports)
  {
    $array = Wasm::Wasmtime::ExternArray->new(scalar @$imports);
    foreach my $i (0..$#$imports)
    {
      _cast_import($imports->[$i], $mi[$i], $store, \@keep, $array->[$i]);
    }
  }

  my $data = Wasm::Wasmtime::InstanceData->new;
  my $trap;
  if(my $error = $xsub->($store->context, $module, $array ? addressof($array) : undef, scalar @$imports, $data, \$trap))
  {
    Carp::croak("error creating instance: " . $error->message);
  }
  if($trap)
  {
    die Wasm::Wasmtime::Trap->new($trap);
  }

  bless {
    data   => $data,
    store  => $store,
    module => $module,
    keep   => \@keep,
  }, $class;
});

# used internally by Wasm::Wasmtime::Linker->instantiate
sub _new_from_data
{
  my($class, $data, $store, $module) = @_;
  bless {
    data   => $data,
    store  => $store,
    module => $module,
    keep   => [],
  }, $class;
}

=head1 METHODS

=head2 module

 my $module = $instance->module;

Returns the L<Wasm::Wasmtime::Module> for this instance.

=cut

sub module { shift->{module} }

=head2 store

 my $store = $instance->store;

Returns the L<Wasm::Wasmtime::Store> for this instance.

=cut

sub store { shift->{store} }

=head2 context

 my $context = $instance->context;

Returns the C<wasmtime_context_t> pointer for this instance's store (internal use).

=cut

sub context { shift->{store}->context }

=head2 exports

 my $exports = $instance->exports;

Returns the L<Wasm::Wasmtime::Instance::Exports> object for this instance.

=cut

sub exports
{
  Wasm::Wasmtime::Instance::Exports->new(shift);
}

$ffi->attach( [ wasmtime_instance_export_nth => '_export_nth' ] => ['opaque','wasmtime_instance_t','size_t','opaque*','size_t*','wasmtime_extern_t'] => 'bool' );

sub _exports
{
  my($self) = @_;
  my @exports;
  for(my $i = 0; ; $i++)
  {
    my $extern = Wasm::Wasmtime::ExternData->new;
    my $name_ptr;
    my $name_len = 0;
    last unless _export_nth($self->context, $self->{data}, $i, \$name_ptr, \$name_len, $extern);
    my $obj = Wasm::Wasmtime::Extern->from_extern($extern, $self->{store});
    $extern->free;
    push @exports, $obj;
  }
  @exports;
}

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
