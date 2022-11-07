use strict;
use warnings;
use Wasm::Wasmtime;

my $module = Wasm::Wasmtime::Module->new( wat => '(module)' );
my $type = $module->type;
