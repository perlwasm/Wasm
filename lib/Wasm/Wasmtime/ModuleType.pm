package Wasm::Wasmtime::ModuleType;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ModuleType::Exports;
use Wasm::Wasmtime::ModuleType::Imports;
use Wasm::Wasmtime::ImportType;
use Wasm::Wasmtime::ExportType;

# ABSTRACT: Wasmtime context class
# VERSION

$ffi_prefix = 'wasmtime_moduletype_';
$ffi->load_custom_type('::PtrObject' => 'wasmtime_moduletype_t' => __PACKAGE__);

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/moduletype.pl

=head1 DESCRIPTION

This class represents the type information of a module.

=head1 METHODS

=head2 imports

 my $imports = $type->imports;

=head2 exports

 my $exports = $type->exports;

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( [ imports => '_imports' ] => ['wasmtime_moduletype_t','wasm_importtype_vec_t*'] => sub {
    my($xsub, $self) = @_;
    my $imports = Wasm::Wasmtime::ImportTypeVec->new;
    $xsub->($self, $imports);
    $imports->to_list;
  });

  $ffi->attach( [ exports => '_exports' ] => ['wasmtime_moduletype_t','wasm_exporttype_vec_t*'] => sub {
    my($xsub, $self) = @_;
    my $exports = Wasm::Wasmtime::ExportTypeVec->new;
    $xsub->($self, $exports);
    $exports->to_list;
  });

  *exports = sub
  {
    Wasm::Wasmtime::ModuleType::Exports->new(shift);
  };

  *imports = sub
  {
    Wasm::Wasmtime::ModuleType::Imports->new(shift);
  };

  _generate_destroy();
}
else
{

  *exports = sub
  {
    my($self) = @_;
    Wasm::Wasmtime::ModuleType::Exports->new($self->{module});
  };

  *imports = sub
  {
    my($self) = @_;
    Wasm::Wasmtime::ModuleType::Imports->new($self->{module});
  };
}


1;
