package Wasm::Wasmtime::Func;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::Trap;
use Convert::Binary::C;
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
$ffi->type('opaque' => 'wasm_func_t');

# CBC is probably not how we want to do this long term, but atm
# Platypus does not support Unions or arrays of records so.
my $c = Convert::Binary::C->new(
  Alignment => 8,
  LongSize => 8, # CBC does not apparently use the native alignment by default *sigh*
);
$c->parse(<<'END');
typedef struct wasm_val_t {
  unsigned char kind;
  union {
    signed int i32;
    signed long i64;
    float f32;
    double f64;
    void *anyref;
    void *funcref;
  } of;
} wasm_val_t;
typedef
typedef wasm_val_t wasm_val_vec_t[];
END

=head1 CONSTRUCTOR

=head2 new

 my $func = Wasm::Wasmtime::Func->new(
   $functype,   # Wasm::Wasmtime::FuncType
   \&callback,  # code reference
 );

Creates a function instance, which can be used to call Perl from WebAssembly.
See L<Wasm::Wasmtime::FuncType> for details on how to specify the function
signature.

=cut

$ffi->attach( new => ['wasm_store_t', 'wasm_functype_t', '(opaque,opaque)->opaque'] => 'wasm_func_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($ptr, $owner, $wrapper, $store);
  if(ref $_[0])
  {
    $store = shift;
    my($functype, $cb) = @_;

    Carp::croak("FIXME: function with parameters") if scalar $functype->params;
    Carp::croak("FIXME: function with results")    if scalar $functype->results;

    $wrapper = $ffi->closure(sub {
      my($params, $results) = @_;

      local $@ = '';
      eval {
        $cb->();
      };
      if(my $error = $@)
      {
        my $trap = Wasm::Wasmtime::Trap->new("$error");
        return delete $trap->{ptr};
      }
      else
      {
        return undef;
      }
    });
    $ptr = $xsub->($store->{ptr}, $functype->{ptr}, $wrapper);
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr     => $ptr,
    owner   => $owner,
    wrapper => $wrapper,
    store   => $store,
  }, $class;
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
  my @args = @_;
  my $args = $c->pack('wasm_val_vec_t', [map {
    my $valtype = $_;
    {
      kind => $valtype->kind_num,
      of => {
        $valtype->kind => shift @args,
      },
    }
  } $self->type->params]);
  my $results = $c->pack('wasm_val_vec_t', [map { { } } $self->type->results]);
  my $trap = $xsub->($self->{ptr}, $args, $results);
  if($trap)
  {
    $trap = Wasm::Wasmtime::Trap->new($trap);
    my $message = $trap->message;
    Carp::croak("trap in wasm function call: $message");
  }
  my @valtypes = $self->type->results;
  return unless @valtypes;
  my @results = map {
    my $valtype = shift @valtypes;
    $_->{of}->{$valtype->kind};
  } @{ $c->unpack('wasm_val_vec_t', $results) };
  wantarray ? @results : $results[0]; ## no critic (Freenode::Wantarray)
});

=head2 type

 my $functype = $func->type;

Returns the L<Wasm::Wasmtime::FuncType> instance which includes the function signature.

=cut

$ffi->attach( type => ['wasm_func_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::FuncType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});

=head2 param_arity

 my $num = $func->param_arity;

Returns the number of arguments the function takes.

=cut

$ffi->attach( param_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

=head2 result_arity

 my $num = $func->param_arity;

Returns the number of results the function returns.

=cut

$ffi->attach( result_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_func_t'] => sub {
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

=cut
