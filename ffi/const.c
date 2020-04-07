#include <ffi_platypus_bundle.h>
#include <wasm.h>
#include <wasmtime.h>

#define ec(name) c->set_uint("Wasm::Wasmtime::" #name, name); \
                 c->set_uint("Wasm::NWasmtime::" #name, name);

void
ffi_pl_bundle_constant(const char *package, ffi_platypus_constant_t *c)
{
  /* wasm_mutability_enum */
  ec(WASM_CONST);
  ec(WASM_VAR);

  /* wasm_valkind_enum */
  ec(WASM_I32);
  ec(WASM_I64);
  ec(WASM_F32);
  ec(WASM_F64);
  ec(WASM_ANYREF);
  ec(WASM_FUNCREF);

  /* wasm_externkind_enum */
  ec(WASM_EXTERN_FUNC);
  ec(WASM_EXTERN_GLOBAL);
  ec(WASM_EXTERN_TABLE);
  ec(WASM_EXTERN_MEMORY);

  /* wasmtime_strategy_enum */
  ec(WASMTIME_STRATEGY_AUTO);
  ec(WASMTIME_STRATEGY_CRANELIFT);
  ec(WASMTIME_STRATEGY_LIGHTBEAM);

  /* wasmtime_opt_level_enum */
  ec(WASMTIME_OPT_LEVEL_NONE);
  ec(WASMTIME_OPT_LEVEL_SPEED);
  ec(WASMTIME_OPT_LEVEL_SPEED_AND_SIZE);
}
