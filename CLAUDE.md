# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`Wasm` is a Perl distribution that lets Perl and WebAssembly call each other transparently.
It is built with **Dist::Zilla** using the `[@Author::Plicease]` plugin bundle (see `dist.ini`).
There is no checked-in `Makefile.PL` / `Build.PL`; those are generated at build time.

WebAssembly execution is provided by the **modern wasmtime C API** (`libwasmtime`, the
`wasmtime_context_t` / `wasmtime_store_t` interface), reached through `FFI::Platypus` — there is
no XS or compiled C in this repo. Developed against **wasmtime 48.0.1**; the pre-1.0 `wasm-c-api`
object model is no longer supported. The library is located by `Wasm::Wasmtime::FFI::_lib` in order: the `WASM_WASMTIME_FFI`
environment variable (full path to `libwasmtime.so` / `.dylib` / `.dll`; use this here —
`~/opt/wasmtime/<version>/lib/libwasmtime.so`), then a plain `FFI::CheckLib` probe for a
system `libwasmtime`, then `Alien::wasmtime` if installed (`dist.ini` has a `[DynamicPrereqs]`
that pulls in `Alien::wasmtime` >= 0.18 — which bundles wasmtime 48.x — when no system library
is found). It dies if none of those work. All three paths probe for the sentinel symbols
`wasmtime_wat2wasm`, `wasmtime_module_new`, `wasmtime_linker_define_wasi`,
`wasmtime_instance_export_nth`, which the feature-reduced ("min", Pulley-only) libwasmtime
lacks — `_lib` walks every `Alien::wasmtime->dynamic_libs` and takes the first *full* build,
because `FFI::CheckLib`'s `alien` option only checks the first candidate.

## Common commands

Requires `dzil` (Dist::Zilla) plus the `Dist::Zilla::PluginBundle::Author::Plicease` bundle.

```sh
dzil test                 # build in a temp dir and run t/*.t
dzil test --author        # also run xt/author/*.t (perlcritic, pod, examples, memory cycles)
dzil test --release       # also run xt/release/*.t
dzil build                # produce a Wasm-<version>/ dir + tarball
dzil regenerate           # refresh generated in-repo files (e.g. t/00_diag.t, README.md)
dzil run <cmd>            # run <cmd> with the built dist in @INC
```

Run a single test file directly (tests need both `lib/` and `t/lib/` in `@INC`, plus the
`WASM_WASMTIME_FFI` env var):

```sh
export WASM_WASMTIME_FFI=$HOME/opt/wasmtime/48.0.1/lib/libwasmtime.so
perl -Ilib -It/lib t/wasm_func.t
prove -lr -It/lib t/          # whole suite
prove -l  -It/lib xt/author/  # critic, cycle, examples
```

Lint (config is `perlcriticrc`: severity 1, `only = 1`, Community policies + selected extras):

```sh
perlcritic --profile perlcriticrc lib
prove -l xt/author/critic.t
```

CI runs in containers via [`cip`](https://github.com/uperl/cip): `.github/workflows/` has
`static` (author/static checks), `linux` (perl 5.10–5.41 matrix), `windows`, `macos`. **The CI
still installs an ancient `Alien::wasmtime` and has not been migrated to the modern C API** —
treat `.github/workflows/*` and `maint/cip-before-install` as a known follow-up.

## Architecture

Two layers, low to high:

### `Wasm::Wasmtime::*` — thin FFI bindings to the wasmtime C API

- `Wasm::Wasmtime::FFI` is the private core. It resolves `libwasmtime` (via `WASM_WASMTIME_FFI`),
  creates the shared `$ffi` (`FFI::Platypus`) object, installs a name mangler that leaves
  `wasm_` / `wasmtime_` / `wasi_` symbols alone and prefixes everything else, and provides
  `_generate_vec_class` / `_generate_destroy(<c_delete_fn>)` code generators. It also defines the
  `FFI::C` structs for the modern **store-handle** POD types — `wasmtime_func_t` (16 b),
  `wasmtime_memory_t` / `wasmtime_table_t` (**24 b** — anonymous-struct tail padding puts
  `__private2` at offset 16, do not use 16), `wasmtime_global_t` (24 b), `wasmtime_instance_t`
  (16 b), `wasmtime_extern_t` (tagged union, 32 b), and `wasmtime_val_t` (32 b).
- The **type layer** (`ValType`, `FuncType`, `GlobalType`, `MemoryType`, `TableType`,
  `ExternType`, `ImportType`, `ExportType`, and all `*Vec` classes) is still plain `wasm.h`
  wasm-c-api and largely unchanged. `ValType` kind 128 is named `anyref` (accepts `externref`
  as an alias).
- The **stateful classes** were rewritten for the context model: `Store` owns
  `wasmtime_store_t*` and exposes `->context` (a borrowed `wasmtime_context_t*`); every live
  object (`Func`, `Memory`, `Global`, `Table`, `Instance`, `Caller`) holds `{ data => <handle
  struct>, store => $store }` and threads `$self->context` into every C call. These handles have
  **no destructor**. `Extern` is a base class + dispatcher: `from_extern($extern_data, $store)`
  copies a `wasmtime_extern_t` into a Func/Memory/Global/Table; `_fill_extern`/`to_extern` go the
  other way for imports and `Linker->define`.
- WASI: there is no `WasiInstance` any more. Configure `WasiConfig` on the store with
  `$store->set_wasi($config)` (consumes it) and call `$linker->define_wasi` (no argument).
- `Wasm::Wasmtime` just `use`s all of the above so callers get every class in one line.
- Typical object graph: `Config` → `Engine` → `Store`; `Module->new($engine, wat|wasm => ...)`;
  `Instance->new($module, $store, \@imports)`; then `$instance->exports->{name}` yields an `Extern`.
- Gotcha: `FFI::Platypus::Buffer::scalar_to_buffer` must be handed a **named lexical** that
  outlives the C call — passing `scalar_to_buffer("$x")` frees the temp before the call and
  corrupts the argument.

### `Wasm` — the Perlish sugar (what most users touch)

`use Wasm -api => 0, -wat => '...'` (or `-file`, or `-self`) loads a WebAssembly module **at
compile time** and installs its exported functions as real Perl subs in the calling package
(or `-package`). Exported memories become tied scalars blessed into `Wasm::Memory`. Key options
(documented fully in `lib/Wasm.pm` POD): `-api` (must be `0`), `-wat`, `-file`, `-self`
(load `Foo/Bar.wasm|.wat` next to `Foo/Bar.pm`), `-package`, `-exporter` (`ok`/`all`, wires the
caller up as an `Exporter`), `-global` (define a Perl-side global importable into Wasm).
`%Wasm::WASM` maps loaded module names to source files (like `%INC`).

Companion user-facing modules — mostly documentation and thin conveniences over the above:
`Wasm::Func`, `Wasm::Global`, `Wasm::Memory`, `Wasm::Table`, `Wasm::Trap`, and `Wasm::Hook`
(installs an `@INC` hook so `use Foo::Bar` transparently loads `Foo/Bar.wasm` when no `.pm` exists).

## Tests and fixtures

- `t/lib/Test2/Tools/Wasm.pm` — test tools `wasm_store`, `wasm_module_ok`, `wasm_instance_ok`,
  `wasm_func_ok`. Uses one shared `Store` singleton (built with `wasm_multi_value` enabled).
- `lib/Test2/Plugin/Wasm.pm` — shipped test plugin. Detects virtual-memory-limited environments
  (`ulimit -v`) and sets `memory_reservation(0)` + `memory_guard_size(0)` so wasmtime does not
  reserve large `PROT_NONE` regions that would OOM. `use Test2::Plugin::Wasm;` at the top of a
  `.t` that instantiates Wasm.
- `corpus/` holds fixture modules: `corpus/wasm/` (Math.pm/.wat/.wasm for `-self`/`-file`),
  `corpus/wasm__linker/` (Linker tests), `corpus/wasm_hook/` (`Wasm::Hook` tests).
- `xt/author/examples.t` compiles and runs every `examples/*/*.pl` and fails on deprecation
  warnings. `examples/synopsis/` files are the *source* for SYNOPSIS POD (see below).

## Generated content — edit the source, not the output

- `t/00_diag.t`, `README.md`, and the `Makefile.PL` in built dists are generated. Change
  `dist.ini` (and re-run `dzil regenerate`), not the generated files.
- In POD, `# EXAMPLE: examples/foo/bar.pl` is replaced at build time with that file's contents
  (`[InsertExample]`, `remove_boiler = 1`). Boilerplate markers `# ABSTRACT:`, `# VERSION`,
  `# PODNAME:` are filled in by the bundle. To change a SYNOPSIS code block, edit the referenced
  file under `examples/`.
- Spelling stopwords and pod-coverage exemptions live in `author.yml`.

## Environment variables

- `WASM_WASMTIME_FFI` — **required**: absolute path to `libwasmtime.so` / `.dylib` / `.dll`.
- `PERL_WASM_WASMTIME_MEMORY` — colon-separated `memory_reservation:memory_guard_size` for
  tuning wasmtime linear-memory allocation in production (set both to `0` to avoid large
  `PROT_NONE` reservations under `ulimit -v`).
