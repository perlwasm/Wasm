package Wasm::Wasmtime::Instance;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::Trap;
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
$ffi->type('opaque' => 'wasm_instance_t');

=head1 CONSTRUCTOR

=head2 new

 my $instance = Wasm::Wasmtime::Instance->new(
   $module     # Wasm::Wasmtime::Module
 );
 my $instance = Wasm::Wasmtime::Instance->new(
   $module,    # Wasm::Wasmtime::Module
   \@imports,  # array reference of Wasm::Wasmtime::Extern
 );

Create a new instance of the instance class.

=cut

$ffi->attach( new => ['wasm_store_t','wasm_module_t','wasm_extern_t[]','opaque*'] => 'wasm_instance_t' => sub {
  my($xsub, $class, $module, $imports) = @_;
  $imports ||= [];
  my @imports = @$imports;
  my $trap;

  {
    my @mi = $module->imports;
    if(@mi != @imports)
    {
      Carp::croak("Got @{[ scalar @imports ]} imports, but expected @{[ scalar @mi ]}");
    }

    @imports = map {
      ref($_) eq 'Wasm::Wasmtime::Extern'
        ? $_->{ptr}
        : eval { $_->can('as_extern') }
          ? $_->as_extern->{ptr}
          : Carp::croak("Non-extern object as import");
    } @imports;
  }
  # TODO: we don't have an interface to module imports yet, but when
  # we do we should validate that the module and instance imports match
  # otherwise SEGV

  my $ptr = $xsub->($module->store->{ptr}, $module->{ptr}, \@imports, \$trap);
  if($ptr)
  {
    return bless {
      ptr    => $ptr,
      module => $module,
    }, $class;
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
  $xsub->($self->{ptr}, $externs);
  $externs->to_list;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_engine_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
