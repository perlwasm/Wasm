use strict;
use warnings;
use Path::Tiny qw( path );
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $module = Wasm::Wasmtime::Module->new( file => path(__FILE__)->parent->child('gcd.wat') );
my $instance = Wasm::Wasmtime::Instance->new($module);
my $gcd = $instance->get_export('gcd');

print "gcd(6,27) = @{[ $gcd->(6,27) ]}\n";
