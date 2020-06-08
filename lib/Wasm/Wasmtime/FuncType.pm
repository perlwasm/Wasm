package Wasm::Wasmtime::FuncType;

use strict;
use warnings;
use 5.008004;
use base qw( Wasm::Wasmtime::ExternType );
use Ref::Util qw( is_arrayref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;
use constant is_functype => 1;
use constant kind => 'functype';

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
$ffi->load_custom_type('::PtrObject' => 'wasm_functype_t' => __PACKAGE__);

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
  if(is_arrayref $_[0] && is_arrayref $_[1])
  {
    # try not to think too much about all of the maps here
    my($params, $results) = map { my $rec = Wasm::Wasmtime::ValTypeVec->new; $rec->set($_) }
                            map { [map { delete $_->{ptr} } map { Wasm::Wasmtime::ValType->new($_) } @$_] } @_;
    my $self = $xsub->($params, $results);
    return $self;
  }
  else
  {
    my($ptr, $owner) = @_;
    bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});

=head1 METHODS

=head2 params

 my @params = $functype->params;

Returns a list of the parameter types for the function type, as L<Wasm::Wasmtime::ValType> objects.

=cut

$ffi->attach( params => ['wasm_functype_t'] => 'wasm_valtype_vec_t*' => sub {
  my($xsub, $self) = @_;
  $xsub->($self)->to_list;
});

=head2 results

 my @params = $functype->results;

Returns a list of the result types for the function type, as L<Wasm::Wasmtime::ValType> objects.

=cut

$ffi->attach( results => ['wasm_functype_t'] => 'wasm_valtype_vec_t*' => sub {
  my($xsub, $self) = @_;
  $xsub->($self)->to_list;
});

=head2 to_string

 my $string = $functype->to_string;

Converts the type into a string for diagnostics.

=cut

sub to_string
{
  my($self) = @_;
  my @params  = map { $_->to_string } $self->params;
  my @results = map { $_->to_string } $self->results;

  my $string = '';
  $string .= "(param @params)" if @params;
  $string .= ' ' if $string && @results;
  $string .= "(result @results)" if @results;
  $string;
}

__PACKAGE__->_cast(0);
_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
