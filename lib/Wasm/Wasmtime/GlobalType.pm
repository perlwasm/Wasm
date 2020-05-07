package Wasm::Wasmtime::GlobalType;

use strict;
use warnings;
use base qw( Wasm::Wasmtime::ExternType );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;
use Ref::Util qw( is_ref );
use Carp ();
use constant is_globaltype => 1;
use constant kind => 'globaltype';

# ABSTRACT: Wasmtime global type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/globaltype.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a module global type.

=cut

$ffi_prefix = 'wasm_globaltype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_globaltype_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $globaltype = Wasm::Wasmtime::GlobalType->new(
   $valtype,     # Wasm::Wasmtime::ValType
   $mutability,  # 'const' or 'var'
 );

Creates a new global type object.

As a shortcut, the type names (ie C<i32>, etc) maybe used instead of a L<Wasm::Wasmtime::ValType>
for C<$valtype>.

C<$mutability> must be one of

=over 4

=item C<cost>

=item C<var>

=back

=cut

my %mutability = (
  const => 0,
  var   => 1,
);

$ffi->attach( new => ['wasm_valtype_t','uint8'] => 'wasm_globaltype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(defined $_[0] && !is_ref($_[0]) && $_[0] =~ /^[0-9]+$/)
  {
    my($ptr, $owner) = @_;
    return bless {
      ptr => $ptr,
      owner => $owner,
    }, $class;
  }
  else
  {
    my($valtype, $mutability) = @_;
    if(ref($valtype) eq 'Wasm::Wasmtime::ValType')
    {
      $valtype = Wasm::Wasmtime::ValType->new($valtype->kind);
    }
    else
    {
      $valtype = Wasm::Wasmtime::ValType->new($valtype);
    }
    Carp::croak("mutability must be one of 'const' or 'var'") unless defined $mutability{$mutability};
    my $self = $xsub->($valtype, $mutability{$mutability});
    delete $valtype->{ptr};
    return $self;
  }
});

=head2 content

 my $valtype = $globaltype->content;

Returns the L<Wasm::Wasmtime::ValType> for this global type.

=cut

$ffi->attach( content => ['wasm_globaltype_t'] => 'wasm_valtype_t' => sub {
  my($xsub, $self) = @_;
  my $valtype = $xsub->($self);
  $valtype->{owner} = $self;
  $valtype;
});

=head2 mutability

 my $mutable = $globaltype->mutability;

Returns the mutability for this global type.  One of either C<const> or C<var>.

=cut

my @mutability = (
  'const',
  'var',
);

$ffi->attach( mutability => ['wasm_globaltype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $mutability[$xsub->($self)];
});

__PACKAGE__->_cast(1);
_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

