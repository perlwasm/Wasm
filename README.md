# Wasm::Hook [![Build Status](https://secure.travis-ci.org/perlwasm/Wasm-Hook.png)](http://travis-ci.org/perlwasm/Wasm-Hook) ![windows](https://github.com/perlwasm/Wasm-Hook/workflows/windows/badge.svg) ![macos](https://github.com/perlwasm/Wasm-Hook/workflows/macos/badge.svg)

Automatically load WebAssembly modules without a Perl wrapper

# SYNOPSIS

```perl
use Wasm::Hook;
use Foo::Bar;  # will load Foo/Bar.wasm or Foo/Bar.wat if no Foo/Bar.pm is found
no Wasm::Hook; # turns off automatic wasm / wat loading 
```

# DESCRIPTION

This module installs an `@INC` hook that automatically loads WebAssembly (Wasm)
files so that they can be used like a Perl module, without:

- Having to write a boilerplate `.pm` file that loads the WebAssembly
- The caller needing to even know or care that the module is implemented in something other than Perl.

This module will only load a WebAssembly module if there is now Perl Module (`.pm` file) with the appropriate name.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
