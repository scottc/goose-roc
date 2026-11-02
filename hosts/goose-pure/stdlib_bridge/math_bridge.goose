// ---- Math (real, via Goose math / libm) ----
import math;

fn f64_ok(x: f64) -> HostMathSinResult {
    // Adjust struct/tag names to match glue types file.
    // Typical Try layout: payload + tag (1 = Ok, 0 = Err).
    HostMathSinResult { p0: x as! u64, p1: 0, p2: 0, tag: 1 }
}

// If glue generated one shared result type, reuse it; if three distinct
// HostMathSinResult / Cos / Sqrt, either duplicate helpers or change Host.roc
// so they share one error union so glue merges types.

fn impl_roc_math_sin(x: f64) -> /* HostMathSinResult */ {
    // Prefer returning raw f64 if glue says -> f64 inside Ok only via full Try struct.
    // Read export: export "roc_math_sin" fn roc_math_sin(arg0: f64) -> HOST_TY
    let y = math.sin(x); // or sin(x) per Goose math API
    // return line_ok-style constructor for F64 Try — mirror your stdout HostLineResult helpers
    abort("impl_roc_math_sin: wire HostMath*Result constructor from glue types");
}

fn impl_roc_math_cos(x: f64) -> /* … */ {
    abort("impl_roc_math_cos: todo");
}

fn impl_roc_math_sqrt(x: f64) -> /* … */ {
    abort("impl_roc_math_sqrt: todo");
}
