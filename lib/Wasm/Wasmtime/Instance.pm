package Wasm::Wasmtime::Instance;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::Trap;

# ABSTRACT: Wasmtime instance class
# VERSION

$ffi_prefix = 'wasm_instance_';
$ffi->type('opaque' => 'wasm_instance_t');

$ffi->attach( new => ['wasm_store_t','wasm_module_t','wasm_extern_t[]','opaque*'] => 'wasm_engine_t' => sub {
  my($xsub, $class, $module, $imports) = @_;
  my @imports = defined $imports ? map { $_->{ptr} } @$imports : ();
  my $trap;
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

=cut

sub module { shift->{module} }

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
