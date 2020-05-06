package Wasm::Wasmtime::Instance;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::Trap;
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

$ffi_prefix = 'wasm_instance_';
$ffi->load_custom_type('::PtrObject' => 'wasm_instance_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $instance = Wasm::Wasmtime::Instance->new(
   $module     # Wasm::Wasmtime::Module
 );
 my $instance = Wasm::Wasmtime::Instance->new(
   $module,    # Wasm::Wasmtime::Module
   \@imports,  # array reference of Wasm::Wasmtime::Extern
 );

Create a new instance of the instance class.  C<@imports> should match the
imports specified by C<$module>.  You can use a few shortcuts when specifying
imports:

=over 4

=item code reference

For a function import, you can provide a plan Perl subroutine, since we can
determine the function signature from the C<$module>.

=item scalar reference

For a memory import, a memory object will be created and the referred scalar
will be set to it.

=item C<undef>

For a memory import, a memory object will be created.  You won't be able to
access it from Perl space, but at least it won't die.

=back

=cut

sub _cast_import
{
  my($ii, $mi, $store, $keep) = @_;
  if(ref($ii) eq 'Wasm::Wasmtime::Extern')
  {
    return $ii->{ptr};
  }
  # TODO: if Wasm::Wasmtime::Extern becomes a baseclass for
  # these four extern classes, then we don't have to check them
  # in this stupid way.
  elsif(is_blessed_ref($ii) && (   $ii->isa('Wasm::Wasmtime::Func')
                                || $ii->isa('Wasm::Wasmtime::Memory')
                                || $ii->isa('Wasm::Wasmtime::Global')
                                || $ii->isa('Wasm::Wasmtime::Table')))
  {
    return $ii->{ptr};
  }
  elsif(is_plain_coderef($ii))
  {
    if($mi->type->kind eq 'func')
    {
      my $f = Wasm::Wasmtime::Func->new(
        $store,
        $mi->type->as_functype,
        $ii,
      );
      push @$keep, $f;
      return $f->{ptr};
    }
  }
  elsif(is_plain_scalarref($ii) || !defined $ii)
  {
    if($mi->type->kind eq 'memory')
    {
      my $m = Wasm::Wasmtime::Memory->new(
        $store,
        $mi->type->as_memorytype,
      );
      $$ii = $m if defined $ii;
      push @$keep, $m;
      return $m->{ptr};
    }
  }
  Carp::croak("Non-extern object as import");
}

$ffi->attach( new => ['wasm_store_t','wasm_module_t','opaque[]','opaque*'] => 'wasm_instance_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $module = shift;

  my $ptr;
  my @keep;

  if(defined $_[0] && !is_ref($_[0]))
  {
    ($ptr) = @_;
    return bless {
      ptr    => $ptr,
      module => $module,
      keep   => \@keep,
    }, $class;
  }
  else
  {
    my($imports) = @_;

    $imports ||= [];
    Carp::confess("imports is not an array reference") unless ref($imports) eq 'ARRAY';
    my @imports = @$imports;
    my $trap;
    my $store = $module->store;

    {
      my @mi = $module->imports;
      if(@mi != @imports)
      {
        Carp::croak("Got @{[ scalar @imports ]} imports, but expected @{[ scalar @mi ]}");
      }

      @imports = map { _cast_import($_, shift @mi, $store, \@keep) } @imports;
    }

    my $self = $xsub->($store, $module, \@imports, \$trap);
    if($self)
    {
      $self->{module} = $module;
      $self->{keep}   = \@keep;
      return $self;
    }
    else
    {
     if($trap)
     {
        $trap = Wasm::Wasmtime::Trap->new($trap);
        Carp::croak($trap->message);
      }
      Carp::croak("error creating Wasm::Wasmtime::Instance ");
    }
  }

});

=head1 METHODS

=head2 get_export

 my $extern = $instance->get_export($name);

Returns a L<Wasm::Wasmtime::Extern> object with the given C<$name>.
If no such object exists, then C<undef> will be returned.

Extern objects represent functions, globals, tables or memory in WebAssembly.

=cut

sub get_export
{
  my($self, $name) = @_;
  $self->{exports} ||= do {
    my @exports = $self->exports;
    my @module_exports   = $self->module->exports;
    my %exports;
    foreach my $i (0..$#exports)
    {
      $exports{$module_exports[$i]->name} = $exports[$i];
    }
    \%exports;
  };
  $self->{exports}->{$name};
}

=head2 module

 my $module = $instance->module;

Returns the L<Wasm::Wasmtime::Module> for this instance.

=cut

sub module { shift->{module} }

=head2 exports

 my @externs = $instance->exports;

Returns a list of L<Wasm::Wasmtime::Extern> objects for the functions,
globals, tables and memory exported by the WebAssembly instance.

=cut

$ffi->attach( exports => ['wasm_instance_t','wasm_extern_vec_t*'] => sub {
  my($xsub, $self) = @_;
  my $externs = Wasm::Wasmtime::ExternVec->new;
  $xsub->($self, $externs);
  $externs->to_list;
});

_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

