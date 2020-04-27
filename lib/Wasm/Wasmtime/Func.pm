package Wasm::Wasmtime::Func;

use strict;
use warnings;
use Ref::Util qw( is_blessed_ref is_plain_arrayref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::Trap;
use Wasm::Wasmtime::CBC qw( perl_to_wasm wasm_allocate wasm_to_perl wasm_type wasm_memcpy );
use Sub::Install;
use Carp ();
use overload
  '&{}' => sub { my $self = shift; sub { $self->call(@_) } },
  bool => sub { 1 },
  fallback => 1;
  ;

# ABSTRACT: Wasmtime function class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/func1.pl

# EXAMPLE: examples/synopsis/func2.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a function, and can be used to either call a WebAssembly function from
Perl, or to create a callback for calling a Perl function from WebAssembly.

=cut

$ffi_prefix = 'wasm_func_';
$ffi->load_custom_type('::PtrObject' => 'wasm_func_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $func = Wasm::Wasmtime::Func->new(
   $store,               # Wasm::Wasmtime::Store
   \@params, \@results,  # array reference for function signature
   \&callback,           # code reference
 );
 my $func = Wasm::Wasmtime::Func->new(
   $store,      # Wasm::Wasmtime::Store
   $functype,   # Wasm::Wasmtime::FuncType
   \&callback,  # code reference
 );

Creates a function instance, which can be used to call Perl from WebAssembly.
See L<Wasm::Wasmtime::FuncType> for details on how to specify the function
signature.

=cut

$ffi->attach( new => ['wasm_store_t', 'wasm_functype_t', 'opaque'] => 'wasm_func_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(is_blessed_ref $_[0] && $_[0]->isa('Wasm::Wasmtime::Store'))
  {
    my $store = shift;
    my($functype, $cb) = is_plain_arrayref($_[0])
       ? (Wasm::Wasmtime::FuncType->new($_[0], $_[1]), $_[2])
       : @_;

    my $param_arity  = scalar $functype->params;
    my $result_arity = scalar$functype->results;

    my $wrapper = $ffi->closure(sub {
      my($params, $results) = @_;

      my @args = $param_arity ? wasm_to_perl($params) : ();

      local $@ = '';
      my @ret = eval {
        $cb->(@args);
      };
      if(my $error = $@)
      {
        my $trap = Wasm::Wasmtime::Trap->new($store, "$error\0");
        return delete $trap->{ptr};
      }
      else
      {
        wasm_memcpy($results, perl_to_wasm(\@ret, [$functype->results])) if $result_arity;
        return undef;
      }
    });
    my $wasm_type = wasm_type($param_arity);
    my $fptr = $ffi->cast("($wasm_type,opaque)->opaque", => 'opaque', $wrapper);
    my $self = $xsub->($store, $functype, $fptr);
    $self->{store} = $store;
    $self->{wrapper} = $wrapper;
    return $self;
  }
  else
  {
    my ($ptr, $owner) = @_;
    bless {
      ptr     => $ptr,
      owner   => $owner,
    }, $class;
  }
});

=head1 METHODS

=head2 call

 my @results = $func->call(@params);
 my @results = $func->(@params);

Calls the function instance.  This can be used to call either Perl functions created
with C<new> as above, or call WebAssembly functions from Perl.  As a convenience you
can call the function by using the function instance like a code reference.

If there is a trap during the call it will throw an exception.  In list context all
of the results are returned as a list.  In scalar context just the first result (if
any) is returned.

=cut

$ffi->attach( call => ['wasm_func_t', 'string', 'string'] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $self = shift;
  my $args = perl_to_wasm(\@_, [$self->type->params]);
  my $results = wasm_allocate( $self->result_arity );

  my $trap = $xsub->($self, $args, $results);

  if($trap)
  {
    $trap = Wasm::Wasmtime::Trap->new($trap);
    my $message = $trap->message;
    Carp::croak("trap in wasm function call: $message");
  }
  return unless defined $results;
  my @results = wasm_to_perl($results);
  wantarray ? @results : $results[0]; ## no critic (Freenode::Wantarray)
});

=head2 attach

 $func->attach($name);
 $func->attach($package, $name);

Attach the function as a Perl subroutine.  If C<$package> is not specified, then the
caller's package will be used.

=cut

sub attach
{
  my $self    = shift;
  my $package = @_ == 2 ? shift : caller;
  my $name    = shift;
  if($package->can($name))
  {
    Carp::carp("attaching ${package}::$name replaces existing subroutine");
  }
  Sub::Install::reinstall_sub({
    code => sub { $self->call(@_) },
    into => $package,
    as   => $name,
  });
}

=head2 type

 my $functype = $func->type;

Returns the L<Wasm::Wasmtime::FuncType> instance which includes the function signature.

=cut

$ffi->attach( type => ['wasm_func_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});

=head2 param_arity

 my $num = $func->param_arity;

Returns the number of arguments the function takes.

=cut

$ffi->attach( param_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 result_arity

 my $num = $func->param_arity;

Returns the number of results the function returns.

=cut

$ffi->attach( result_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 as_extern

 my $extern = $func->as_extern;

Returns the L<Wasm::Wasmtime::Extern> for this function.

=cut

# actually returns a wasm_extern_t, but recursion
$ffi->attach( as_extern => ['wasm_func_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::Extern;
  my $ptr = $xsub->($self);
  Wasm::Wasmtime::Extern->new($ptr, $self->{owner} || $self);
});

#_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut

