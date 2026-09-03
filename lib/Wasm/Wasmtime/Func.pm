package Wasm::Wasmtime::Func;

use strict;
use warnings;
use 5.008004;
use base qw( Wasm::Wasmtime::Extern );
use Ref::Util qw( is_blessed_ref is_plain_arrayref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::Trap;
use FFI::C::Util qw( addressof set_array_count );
use Sub::Install;
use Carp ();
use constant is_func => 1;
use constant kind => 'func';
use overload
  '&{}' => sub { my $self = shift; sub { $self->call(@_) } },
  bool => sub { 1 },
  fallback => 1;

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

my $val_array_from_ptr = sub {
  my($ptr, $n) = @_;
  return undef unless $n;
  my $array = $ffi->cast('opaque', 'wasmtime_val_array_t', $ptr);
  set_array_count($array, $n);
  $array;
};

my $set_val = sub {
  my($slot, $kind, $value) = @_;
  if($kind eq 'i32')    { $slot->of->i32($value) }
  elsif($kind eq 'i64') { $slot->of->i64($value) }
  elsif($kind eq 'f32') { $slot->of->f32($value) }
  elsif($kind eq 'f64') { $slot->of->f64($value) }
  else { Carp::croak("cannot marshal WebAssembly value of type $kind") }
  $slot->kind($Wasm::Wasmtime::FFI::VAL_KIND_NUM{$kind});
};

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

$ffi->attach( [ wasmtime_func_new => 'new' ] => ['opaque', 'wasm_functype_t', '(opaque,opaque,opaque,size_t,opaque,size_t)->opaque', 'opaque', 'opaque', 'wasmtime_func_t'] => 'void' => sub {
  my $xsub = shift;
  my $class = shift;

  Carp::croak("Wasm::Wasmtime::Func->new requires a Wasm::Wasmtime::Store")
    unless is_blessed_ref($_[0]) && $_[0]->isa('Wasm::Wasmtime::Store');
  my $store = shift;

  my($functype, $cb) = is_plain_arrayref($_[0])
     ? (Wasm::Wasmtime::FuncType->new($_[0], $_[1]), $_[2])
     : @_;

  my @result_types = $functype->results;
  my $param_arity  = scalar $functype->params;
  my $result_arity = scalar @result_types;

  require Wasm::Wasmtime::Caller;

  my $closure = $ffi->closure(sub {
    my(undef, $caller_ptr, $args_ptr, $nargs, $res_ptr, $nres) = @_;

    my $caller = Wasm::Wasmtime::Caller->new($caller_ptr, $store);
    unshift @Wasm::Wasmtime::Caller::callers, $caller;

    my @args;
    if($nargs)
    {
      my $array = $val_array_from_ptr->($args_ptr, $nargs);
      @args = map { $_->to_perl } @$array;
    }

    local $@ = '';
    my @ret = eval { $cb->(@args) };
    if(my $error = $@)
    {
      shift @Wasm::Wasmtime::Caller::callers;
      delete $caller->{ptr};
      my $trap = is_blessed_ref($error) && $error->isa('Wasm::Wasmtime::Trap')
        ? $error
        : Wasm::Wasmtime::Trap->new("$error");
      return delete $trap->{ptr};
    }

    if($nres)
    {
      my $array = $val_array_from_ptr->($res_ptr, $nres);
      foreach my $i (0..$nres-1)
      {
        $set_val->($array->[$i], $result_types[$i]->kind, $ret[$i]);
      }
    }

    shift @Wasm::Wasmtime::Caller::callers;
    delete $caller->{ptr};
    return undef;
  });

  my $data = Wasm::Wasmtime::FuncData->new;
  $xsub->($store->context, $functype, $closure, undef, undef, $data);

  bless {
    data     => $data,
    store    => $store,
    closure  => $closure,
    functype => $functype,
  }, $class;
});

=head1 METHODS

=head2 call

 my @results = $func->call(@params);
 my @results = $func->(@params);

Calls the function instance.  If there is a trap during the call it will throw an
exception.  In list context all of the results are returned as a list.  In scalar
context just the first result (if any) is returned.

=cut

$ffi->attach( [ wasmtime_func_call => 'call' ] => ['opaque', 'wasmtime_func_t', 'opaque', 'size_t', 'opaque', 'size_t', 'opaque*'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $self = shift;

  my $functype    = $self->type;
  my @param_types = $functype->params;
  my @result_types = $functype->results;

  my $args = @param_types
    ? Wasm::Wasmtime::ValArray->from_perl([@_], \@param_types)
    : undef;
  my $results = @result_types
    ? Wasm::Wasmtime::ValArray->new(scalar @result_types)
    : undef;

  my $trap;
  my $error = $xsub->(
    $self->context, $self->{data},
    $args ? addressof($args) : undef, scalar @param_types,
    $results ? addressof($results) : undef, scalar @result_types,
    \$trap,
  );

  # A host function invoked directly returns its failure as an error rather
  # than via the trap out-parameter; surface both as a trap for consistency
  # with how WebAssembly-side traps are reported.
  die Wasm::Wasmtime::Trap->from_error($error) if $error;
  die Wasm::Wasmtime::Trap->new($trap) if $trap;

  return unless defined $results;
  my @out = $results->to_perl;
  wantarray ? @out : $out[0];  ## no critic (Community::Wantarray)
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

$ffi->attach( [ wasmtime_func_type => '_type' ] => ['opaque', 'wasmtime_func_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->context, $self->{data});
});

sub type
{
  my($self) = @_;
  $self->{functype} ||= $self->_type;
}

=head2 param_arity

 my $num = $func->param_arity;

Returns the number of arguments the function takes.

=head2 result_arity

 my $num = $func->result_arity;

Returns the number of results the function returns.

=cut

sub param_arity  { scalar shift->type->params }
sub result_arity { scalar shift->type->results }

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
