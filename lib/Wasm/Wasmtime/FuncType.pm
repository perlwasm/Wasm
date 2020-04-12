package Wasm::Wasmtime::FuncType;

use strict;
use warnings;
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;

# ABSTRACT: Wasmtime function type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/functype.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

The function type class represents a function signature, that is the parameter and return
types that a function will take.

=cut

$ffi_prefix = 'wasm_functype_';
$ffi->type('opaque' => 'wasm_functype_t');

=head1 CONSTRUCTOR

=head2 new

 my $functype = Wasm::Wasmtime::FuncType->new(\@params, \@results);

Creates a new function type instance.  C<@params> and C<@results> should be a list of
either L<Wasm::Wasmtime::ValType> objects, or the string representation of those types
(C<i32>, C<f64>, etc).

=cut

$ffi->attach( new => ['wasm_valtype_vec_t*', 'wasm_valtype_vec_t*'] => 'wasm_functype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($ptr, $owner);
  if(is_ref $_[0])
  {
    # try not to think too much about all of the maps here
    my($params, $results) = map { my $rec = Wasm::Wasmtime::ValTypeVec->new; $rec->set($_) }
                            map { [map { delete $_->{ptr} } map { Wasm::Wasmtime::ValType->new($_) } @$_] } @_;
    $ptr = $xsub->($params, $results);
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
});

=head1 METHODS

=head2 params

 my @params = $functype->params;

Returns a list of the parameter types for the function type, as L<Wasm::Wasmtime::ValType> objects.

=cut

$ffi->attach( params => ['wasm_functype_t'] => 'wasm_valtype_vec_t*' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr})->to_list;
});

=head2 results

 my @params = $functype->results;

Returns a list of the result types for the function type, as L<Wasm::Wasmtime::ValType> objects.

=cut

$ffi->attach( results => ['wasm_functype_t'] => 'wasm_valtype_vec_t*' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr})->to_list;
});

=head2 as_externtype

 my $externtype = $func->as_externtype

Returns the L<Wasm::Wasmtime::ExternType> for this function type.

=cut

# actually returns a wasm_externtype_t, but recursion
$ffi->attach( as_externtype => ['wasm_functype_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::ExternType;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::ExternType->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_functype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

