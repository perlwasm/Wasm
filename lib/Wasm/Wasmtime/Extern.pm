package Wasm::Wasmtime::Extern;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

require Wasm::Wasmtime::Func;
require Wasm::Wasmtime::Global;
require Wasm::Wasmtime::Table;
require Wasm::Wasmtime::Memory;

# ABSTRACT: Wasmtime extern class
# VERSION

=head1 DESCRIPTION

This is a private class.  The C<.pm> file for it may be removed in the future.

=cut

$ffi_prefix = 'wasm_extern_';

$ffi->attach( [ kind => '_kind' ] => ['opaque'] => 'uint8' );

our @cast =
  map { $ffi->function( "wasm_extern_as_$_" => ['opaque'] => "wasm_${_}_t")->sub_ref }
  qw( func global table memory );

$ffi->custom_type('wasm_extern_t' => {
  native_type => 'opaque',
  native_to_perl => sub {
    my $extern = shift;
    Carp::croak("extern error") unless defined $extern;
    my $kind = _kind($extern);
    $cast[$kind]->($extern);
  },
});

# TODO: use a wrapper if
# https://github.com/Perl5-FFI/FFI-Platypus/issues/261
# lands
$ffi->attach_cast('_new', 'opaque', 'wasm_extern_t');

sub new
{
  my($class, $ptr, $owner) = @_;
  my $self = _new($ptr);
  $self->{owner} = $owner;
  $self;
}

_generate_vec_class();

1;
