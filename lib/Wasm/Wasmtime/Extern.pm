package Wasm::Wasmtime::Extern;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime extern class
# VERSION

$ffi->mangler(sub { "wasm_extern_$_[0]" });
$ffi->type('opaque' => 'wasm_extern_t');

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_extern_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
