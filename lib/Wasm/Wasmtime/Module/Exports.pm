package Wasm::Wasmtime::Module::Exports;

use strict;
use warnings;
use Carp qw( croak );

croak("This class was renamed to Wasm::Wasmtime::ModuleType::Exports") unless caller eq 'Pod::Coverage';

1;

# ABSTRACT: Old class
# VERSION

__END__

=head1 SYNOPSIS

 $ perldoc Wasm::Wasmtime::ModuleType::Exports

=head1 DESCRIPTION

This is the old class name for L<Wasm::Wasmtime::ModuleType::Exports>.
Trying to use this class name will throw an exception.

=cut
