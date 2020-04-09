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

$ffi_prefix = 'wasm_func_';
$ffi->type('opaque' => 'wasm_func_t');

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

$ffi->attach( type => ['wasm_func_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::FuncType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});

$ffi->attach( param_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

$ffi->attach( result_arity => ['wasm_func_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

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
  my $results = $c->pack('wasm_val_vec_t', [map { { kind => $_->kind_num } } $self->type->results]);
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

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_func_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
