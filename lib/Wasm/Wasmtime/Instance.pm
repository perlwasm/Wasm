package Wasm::Wasmtime::Instance;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::Func;
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

$ffi_prefix = 'wasm_instance_';
$ffi->load_custom_type('::PtrObject' => 'wasm_instance_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $instance = Wasm::Wasmtime::Instance->new(
   $module,    # Wasm::Wasmtime::Module
   $store      # Wasm::Wasmtime::Store
 );
 my $instance = Wasm::Wasmtime::Instance->new(
   $module,    # Wasm::Wasmtime::Module
   $store,     # Wasm::Wasmtime::Store
   \@imports,  # array reference of Wasm::Wasmtime::Extern
 );
 
 # deprecated usage: without $store
 my $instance = Wasm::Wasmtime::Instance->new(
   $module     # Wasm::Wasmtime::Module
 );
 # deprecated usage: without $store
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

[B<Deprecated>: Will be removed in a future version of L<Wasm::Wasmtime>]

You can create an L<Wasm::Wasmtime::Instance> instance without a
L<Wasm::Wasmtime::Store> object, but this usage is deprecated, and will
be removed from a future version of L<Wasm::Wasmtime>.

=cut

sub _cast_import
{
  my($ii, $mi, $store, $keep) = @_;
  if(ref($ii) eq 'Wasm::Wasmtime::Extern')
  {
    return $ii->{ptr};
  }
  elsif(is_blessed_ref($ii) && $ii->isa('Wasm::Wasmtime::Extern'))
  {
    return $ii->{ptr};
  }
  elsif(is_plain_coderef($ii))
  {
    if($mi->type->kind eq 'functype')
    {
      my $f = Wasm::Wasmtime::Func->new(
        $store,
        $mi->type,
        $ii,
      );
      push @$keep, $f;
      return $f->{ptr};
    }
  }
  elsif(is_plain_scalarref($ii) || !defined $ii)
  {
    if($mi->type->kind eq 'memorytype')
    {
      my $m = Wasm::Wasmtime::Memory->new(
        $store,
        $mi->type,
      );
      $$ii = $m if defined $ii;
      push @$keep, $m;
      return $m->{ptr};
    }
  }
  Carp::croak("Non-extern object as import");
}

$ffi->attach( [ wasmtime_instance_new => 'new' ] => ['wasm_store_t','wasm_module_t','opaque[]','size_t','opaque*','opaque*'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $module = shift;
  my $store = is_blessed_ref($_[0]) && $_[0]->isa('Wasm::Wasmtime::Store')
    ? shift
    : do {
      if(warnings::enabled("deprecated"))
      {
        Carp::carp('Creating a Wasm::Wasmtime::Instance instance without a Wasm::Wasmtime::Store object is deprecated and will be removed in a future version of Wasm::Wasmtime');
      }
      no warnings 'deprecated';
      $module->store;
    };

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

    {
      my @mi = @{ $module->imports };
      if(@mi != @imports)
      {
        Carp::croak("Got @{[ scalar @imports ]} imports, but expected @{[ scalar @mi ]}");
      }

      @imports = map { _cast_import($_, shift @mi, $store, \@keep) } @imports;
    }

    my $ptr;
    if(my $error = $xsub->($store, $module, \@imports, scalar(@imports), \$ptr, \$trap))
    {
      Carp::croak("error creating module: " . $error->message);
    }
    else
    {
      if($trap)
      {
        $trap = Wasm::Wasmtime::Trap->new($trap);
        Carp::croak($trap->message);
      }
      else
      {
        return bless {
          ptr    => $ptr,
          module => $module,
          keep   => \@keep,
        }, $class;
      }
    }
  }

});

=head1 METHODS

=head2 module

 my $module = $instance->module;

Returns the L<Wasm::Wasmtime::Module> for this instance.

=cut

sub module { shift->{module} }

=head2 exports

 my $exports = $instance->exports;

Returns the L<Wasm:Wasmtime::Instance::Exports> object for this instance.
This can be used to query and call exports from the instance.

=cut

sub exports
{
  Wasm::Wasmtime::Instance::Exports->new(shift);
}

$ffi->attach( [ exports => '_exports' ] => ['wasm_instance_t','wasm_extern_vec_t*'] => sub {
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

=cut
