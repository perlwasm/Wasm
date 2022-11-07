use strict;
use warnings;

# Call Perl from Wasm
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $module = Wasm::Wasmtime::Module->new( $store->engine, wat => q{
  (module
    (func $hello (import "" "hello"))
    (func (export "run") (call $hello))
  )
});

my $hello = Wasm::Wasmtime::Func->new(
  $store->context,
  Wasm::Wasmtime::FuncType->new([],[]),
  sub { print "hello world!\n" },
);

my $instance = Wasm::Wasmtime::Instance->new($module, $store->context, [$hello]);
$instance->exports->run->call(); # hello world!

