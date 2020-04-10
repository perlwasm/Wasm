use strict;
use warnings;
use Wasm::Wasmtime;
use Path::Tiny qw( path );

# Almost all operations in wasmtime require a contextual "store" argument to be
# shared amongst objects
my $store = Wasm::Wasmtime::Store->new;

# Here we can compile a `Module` which is then ready for instantiation
# afterwards
my $module = Wasm::Wasmtime::Module->new( file => path(__FILE__)->parent->child('hello.wat') );

# Our module needs one import, so we'll create that here.
sub say_hello
{
  print "Hello from Perl!";
}

my $hello = Wasm::Wasmtime::Func->new(
  $store,
  Wasm::Wasmtime::FuncType->new([],[]),
  \&say_hello,
);

## And with all that we can instantiate our module and call the export!
#my $instance = Wasm::Wasmtime::Instance->new($module, [$hello]);
#$instance->get_export("run")->();
