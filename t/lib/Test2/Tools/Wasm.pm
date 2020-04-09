package Test2::Tools::Wasm;

use strict;
use warnings;
use Test2::API qw( context );
use base qw( Exporter );

our @EXPORT = qw( wasm_func_ok );

sub wasm_func_ok ($$)
{
  my $f = shift;
  my $wat = shift;
  require Wasm::Wasmtime;

  my $ctx = context();
  my $name = "function $f";

  local $@ = '';
  my $store = eval {
    my $config = Wasm::Wasmtime::Config->new;
    $config->wasm_multi_value(1);
    my $engine = Wasm::Wasmtime::Engine->new($config);
    Wasm::Wasmtime::Store->new($engine);
  };
  return $ctx->fail_and_release($name, "error creating store object", "$@") if $@;

  my $module = eval { Wasm::Wasmtime::Module->new($store, wat => $wat) };
  return $ctx->fail_and_release($name, "error loading module", "$@") if $@;

  my $instance = eval { Wasm::Wasmtime::Instance->new($module) };
  return $ctx->fail_and_release($name, "error creating instance", "$@") if $@;

  my $extern = $instance->get_export($f);
  return $ctx->fail_and_release($name, "no export $f") unless $extern;

  my $kind = $extern->type->kind;
  return $ctx->fail_and_release($name, "$f is a $kind, expected a func") unless $kind eq 'func';

  $ctx->pass_and_release($name);

  return $extern->as_func;
}

1;
