package Wasm::Wasmtime::FFI;

use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::Platypus::Buffer ();
use FFI::CheckLib 0.26 qw( find_lib );
use base qw( Exporter );

# ABSTRACT: Private class for Wasm::Wasmtime
# VERSION

our @EXPORT = qw( $ffi $ffi_prefix _generate_vec_class );

sub _lib
{
  find_lib lib => 'wasmtime', alien => 'Alien::wasmtime';
}

our $ffi_prefix = 'wasm_';
our $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(__PACKAGE__->_lib);
$ffi->mangler(sub {
  my $name = shift;
  return $name if $name =~ /^(wasm|wasmtime)_/;
  return $ffi_prefix . $name;
});

{ package Wasm::Wasmtime::Vec;
  use FFI::Platypus::Record;
  record_layout_1(
    $ffi,
    size_t => 'size',
    opaque => 'data',
  );
}

{ package Wasm::Wasmtime::ByteVec;
  use base qw( Wasm::Wasmtime::Vec );

  $ffi->type('record(Wasm::Wasmtime::ByteVec)' => 'wasm_byte_vec_t');
  $ffi_prefix = 'wasm_byte_vec_';

  sub new
  {
    my $class = shift;
    if(@_ == 1)
    {
      my($data, $size) = FFI::Platypus::Buffer::scalar_to_buffer($_[0]);
      return $class->SUPER::new(
        size => $size,
        data => $data,
      );
    }
    else
    {
      return $class->SUPER::new(@_);
    }
  }

  sub get
  {
    my($self) = @_;
    FFI::Platypus::Buffer::buffer_to_scalar($self->data, $self->size);
  }

  $ffi->attach( delete => ['wasm_byte_vec_t*'] => 'void' );
}

sub _generic_vec_delete
{
  my($xsub, $self) = @_;
  $xsub->($self);
  # cannot use SUPER::DELETE because we aren't
  # in the right package.
  Wasm::Wasmtime::Vec::DESTROY($self);
}

sub _generate_vec_class
{
  my %opts = @_;
  my($class) = caller;
  my $type = $class;
  $type =~ s/^.*:://;
  my $v_type = "wasm_@{[ lc $type ]}_vec_t";
  my $c_type = "wasm_@{[ lc $type ]}_t";
  my $vclass  = "Wasm::Wasmtime::${type}Vec";
  my $prefix = "wasm_@{[ lc $type ]}_vec";

  my $to_list = sub {
    my($self) = @_;
    my $size = $self->size;
    my $ptrs = $ffi->cast('opaque', "${c_type}[$size]", $self->data);
    map { $class->new($_, $self) } @$ptrs;
  };

  {
    no strict 'refs';
    @{join '::', $vclass, 'ISA'} = ('Wasm::Wasmtime::Vec');
    *{join '::', $vclass, 'to_list'} = $to_list;
  }
  $ffi_prefix = "${prefix}_";
  $ffi->type("record($vclass)" => $v_type);
  $ffi->attach( [ delete => join('::', $vclass, 'DESTROY') ] => ["$v_type*"] => \&_generic_vec_delete)
    if !defined($opts{delete}) || $opts{delete};

}

1;
