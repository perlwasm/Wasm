# Wasm [![Build Status](https://secure.travis-ci.org/perlwasm/Wasm.png)](http://travis-ci.org/perlwasm/Wasm) ![windows](https://github.com/perlwasm/Wasm/workflows/windows/badge.svg) ![macos](https://github.com/perlwasm/Wasm/workflows/macos/badge.svg)

Write Perl extensions using Wasm

# SYNOPSIS

```perl
use Wasm
  -api => 0,
  -wat => '(module)';
```

# DESCRIPTION

**WARNING**: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

The `Wasm` Perl dist provides tools for writing Perl bindings using WebAssembly (Wasm).

# SEE ALSO

- [Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime)

    Low level interface to `wasmtime`.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
