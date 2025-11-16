---
description: "Enforce compiler optimization strategies including release profiles, LTO, inlining directives, SIMD usage, const evaluation, and zero-cost abstraction patterns for maximum runtime performance"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - "./rust-profiling-analysis.md"
  - "./rust-benchmarking.md"
  - "./rust-memory-optimization.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

## Cohesion Principle

**WHY These Aspects Belong Together:**

Compiler optimization techniques form a unified performance enhancement strategy where each mechanism targets a different phase of compilation. Release profiles configure the optimizer's behavior globally, LTO enables cross-crate inlining and dead code elimination, inlining directives guide the compiler's inlining heuristics at function granularity, SIMD exploits data-level parallelism within instructions, const evaluation shifts computation from runtime to compile-time, and zero-cost abstractions eliminate abstraction overhead through monomorphization. These techniques are interdependent: LTO cannot inline across crates without proper release profile settings, SIMD benefits from inlining to reduce call overhead, const evaluation enables compile-time optimizations that LTO can further optimize. Separating these concepts would fragment the optimization pipeline - configuring release profiles without understanding LTO limits cross-crate optimization, using SIMD without inlining wastes vectorization opportunities, and pursuing zero-cost abstractions without const evaluation misses compile-time optimization potential.

---

## Description

Compiler optimization techniques in Rust leverage the type system and LLVM backend to achieve C/C++-level performance through zero-cost abstractions. This rule enforces systematic use of release profile configuration, link-time optimization (LTO), strategic inlining directives, SIMD vectorization, const evaluation for compile-time computation, and zero-cost abstraction patterns (generics over trait objects) to maximize runtime performance while maintaining code clarity and type safety.

---

## Rule

### 1. Configure Aggressive Release Profiles

**MANDATORY**: Always configure release profiles for production builds with aggressive optimizations.

**Recommended Release Profile:**
```toml
# Cargo.toml
[profile.release]
opt-level = 3           # Maximum optimization
lto = "fat"            # Full link-time optimization
codegen-units = 1      # Maximum optimization (slower compile, faster runtime)
strip = true           # Strip symbols for smaller binary
panic = "abort"        # Abort on panic (no unwinding overhead)
```

**Opt-Level Tradeoffs:**
- `opt-level = 0`: No optimization (debug builds)
- `opt-level = 1`: Basic optimizations (faster compile)
- `opt-level = 2`: Recommended optimizations (balanced)
- `opt-level = 3`: Aggressive optimizations (slower compile, best runtime)
- `opt-level = "s"`: Optimize for size
- `opt-level = "z"`: Aggressively optimize for size

**Detection**: Production builds without explicit `[profile.release]` configuration.

### 2. Enable Link-Time Optimization (LTO) for Performance-Critical Binaries

**MANDATORY**: Use LTO for binaries where runtime performance is critical (skip for libraries).

**LTO Modes:**
```toml
[profile.release]
lto = false      # No LTO (default) - fastest compile
lto = "thin"     # Thin LTO - parallel LTO with some cross-crate optimization
lto = "fat"      # Fat LTO - full cross-crate optimization (slowest compile, best runtime)
```

**When to Use LTO:**
- ✅ Performance-critical binaries (servers, CLI tools, games)
- ✅ Release builds for production deployment
- ❌ Libraries (users control LTO via their Cargo.toml)
- ❌ Debug builds (compile time priority)

**Tradeoff**: LTO increases compile time significantly (2-10x) but enables cross-crate inlining and dead code elimination.

**Detection**: Performance-critical binaries without `lto = "thin"` or `lto = "fat"`.

### 3. Use Inlining Directives for Hot Path Functions

**MANDATORY**: Apply `#[inline]` to hot path functions (identified via profiling) that are called frequently across crate boundaries.

**Inlining Strategy:**
```rust
// #[inline]: Suggest inlining (compiler decides)
#[inline]
pub fn frequently_called_small_function(x: u32) -> u32 {
    x * 2 + 1
}

// #[inline(always)]: Force inlining (use sparingly - can increase code size)
#[inline(always)]
pub fn critical_hot_path(x: u32) -> u32 {
    x.wrapping_add(42)
}

// #[inline(never)]: Prevent inlining (useful for debugging or code size)
#[inline(never)]
pub fn complex_cold_function(data: &[u8]) -> Vec<u8> {
    // Large function body
}
```

**Inlining Guidelines:**
- **Small functions (<10 lines)**: Use `#[inline]` if called frequently
- **Critical hot paths**: Use `#[inline(always)]` after profiling confirms benefit
- **Large functions (>50 lines)**: Avoid inlining (code bloat)
- **Generic functions**: Already inlined across crates (no annotation needed)

**Detection**: Hot path functions (>5% profiling time, cross-crate calls) without `#[inline]`.

### 4. Leverage SIMD for Data-Parallel Operations

**MANDATORY**: Use SIMD (Single Instruction Multiple Data) for data-parallel operations on large arrays/slices.

**Portable SIMD (Stable Rust):**
```rust
// Enable portable_simd feature
#![feature(portable_simd)]

use std::simd::prelude::*;

pub fn sum_f32_simd(values: &[f32]) -> f32 {
    let lanes = f32x8::LANES;
    let (chunks, remainder) = values.as_chunks::<8>();

    // Process 8 floats at a time with SIMD
    let sum_vector: f32x8 = chunks
        .iter()
        .map(|chunk| f32x8::from_array(*chunk))
        .fold(f32x8::splat(0.0), |acc, v| acc + v);

    // Horizontal sum + remainder
    sum_vector.reduce_sum() + remainder.iter().sum::<f32>()
}
```

**Auto-Vectorization (Compiler SIMD):**
```rust
// Compiler auto-vectorizes simple loops
pub fn multiply_slices(a: &[f32], b: &[f32], out: &mut [f32]) {
    for i in 0..a.len() {
        out[i] = a[i] * b[i]; // LLVM auto-vectorizes this
    }
}
```

**When to Use Explicit SIMD:**
- Data-parallel operations (element-wise math, filters, reductions)
- Large arrays/slices (>1000 elements)
- Hot paths identified via profiling
- Operations not auto-vectorized by compiler

**Detection**: Data-parallel hot paths (>5% time) without SIMD optimization.

### 5. Use Const Evaluation for Compile-Time Computation

**MANDATORY**: Move runtime computations to compile-time using `const fn` and `const` generics.

**Const Functions:**
```rust
// Compile-time computation
const fn factorial(n: u32) -> u32 {
    match n {
        0 | 1 => 1,
        _ => n * factorial(n - 1),
    }
}

// Evaluated at compile-time
const FACTORIAL_10: u32 = factorial(10); // No runtime cost

// Const generics for zero-cost array sizes
pub struct FixedBuffer<const N: usize> {
    data: [u8; N],
}

impl<const N: usize> FixedBuffer<N> {
    pub const fn new() -> Self {
        Self { data: [0; N] }
    }

    pub const fn capacity() -> usize {
        N // Computed at compile-time
    }
}
```

**Const Evaluation Opportunities:**
- Configuration constants (buffer sizes, magic numbers)
- Lookup table generation
- Compile-time validation (array sizes, protocol magic numbers)
- Zero-cost array initialization

**Detection**: Runtime computations of compile-time constants without `const fn`.

### 6. Prefer Zero-Cost Abstractions (Generics Over Trait Objects)

**MANDATORY**: Use generics (static dispatch) for hot paths instead of trait objects (dynamic dispatch).

**Zero-Cost Abstraction Pattern:**
```rust
// ✅ CORRECT: Generic (static dispatch, monomorphized, inlined)
pub fn process<T: Processor>(items: &[Data], processor: &T) {
    for item in items {
        processor.process(item); // Inlined, no vtable lookup
    }
}

// ❌ INCORRECT: Trait object (dynamic dispatch, vtable overhead)
pub fn process_dynamic(items: &[Data], processor: &dyn Processor) {
    for item in items {
        processor.process(item); // Virtual call, cannot inline
    }
}
```

**When Trait Objects Are Acceptable:**
- Heterogeneous collections (different types in same Vec)
- Plugin systems (dynamic loading)
- Cold paths (<5% profiling time)

**Detection**: Trait objects (`dyn Trait`) in hot paths (>5% profiling time).

### 7. Use Profile-Guided Optimization (PGO) for Production Binaries

**MANDATORY**: Apply PGO for production binaries to enable data-driven compiler optimizations.

**PGO Workflow:**
```bash
# Step 1: Build instrumented binary
RUSTFLAGS="-Cprofile-generate=/tmp/pgo-data" cargo build --release

# Step 2: Run representative workload to collect profiling data
./target/release/binary --workload typical_usage

# Step 3: Build optimized binary with profiling data
RUSTFLAGS="-Cprofile-use=/tmp/pgo-data/merged.profdata" cargo build --release
```

**PGO Benefits:**
- Inlining decisions based on actual call frequency
- Branch prediction hints from real workload patterns
- Code layout optimization for instruction cache locality

**Detection**: Production binaries without PGO for performance-critical applications.

### 8. Use Alternative Allocators

**Consider using a different global allocator, such as `jemalloc` or `mimalloc`, which can provide significant performance improvements for allocation-heavy workloads.**

```rust
use mimalloc::MiMalloc;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;
```

### 9. Compile with CPU-Specific Instructions

**For maximum performance on a specific machine, compile with `RUSTFLAGS="-C target-cpu=native"` to enable CPU-specific instructions like AVX.**

```bash
RUSTFLAGS="-C target-cpu=native" cargo build --release
```
**Note**: This produces a binary that may not run on older CPUs.

---

## Implementation

Cursor IDE and build tools should enforce these practices through:

**Cargo.toml Validation:**
- Detect missing `[profile.release]` section in workspace roots
- Flag binaries without LTO configuration for performance-critical projects
- Verify `opt-level = 3` for production releases

**Inlining Analysis:**
- Parse profiling data (cargo flamegraph, perf) to identify hot path functions
- Cross-reference hot paths with function definitions lacking `#[inline]`
- Suggest `#[inline]` for small (<10 LOC), frequently called functions

**SIMD Opportunity Detection:**
- Identify data-parallel loops (element-wise operations on slices)
- Check for explicit SIMD usage or auto-vectorization hints
- Flag hot path loops without SIMD optimization

**Const Evaluation:**
- Detect runtime computation of compile-time constants
- Suggest `const fn` for pure functions computing constants
- Identify opportunities for `const` generics (array sizes, buffer capacities)

**Zero-Cost Abstraction Enforcement:**
- Parse profiling call graphs for dynamic dispatch (`<dyn Trait>`) in hot paths
- Suggest generic alternatives for trait objects in performance-critical code
- Validate generic functions are properly monomorphized

---

## Benefits

Compiler optimization techniques ensure:

- **Maximum Runtime Performance**: Aggressive optimization (opt-level 3, LTO) achieves C/C++-level speed
- **Zero-Cost Abstractions**: Generics eliminate abstraction overhead through monomorphization
- **Compile-Time Computation**: Const evaluation shifts work from runtime to compile-time (zero runtime cost)
- **Data-Level Parallelism**: SIMD exploits CPU vector units for multi-element operations per instruction
- **Cross-Crate Optimization**: LTO enables inlining and dead code elimination across crate boundaries
- **Profile-Guided Precision**: PGO optimizes for actual workload patterns, not generic heuristics

---

## Examples

### ✅ CORRECT: Aggressive Release Profile with LTO

```toml
# Cargo.toml - Performance-critical binary configuration
[profile.release]
opt-level = 3          # Maximum optimization
lto = "fat"           # Full cross-crate optimization
codegen-units = 1     # Single codegen unit for maximum optimization
strip = true          # Strip symbols (smaller binary)
panic = "abort"       # Abort on panic (no unwinding overhead)
overflow-checks = false  # Disable overflow checks (safety tradeoff)

# For faster compile times, consider a faster linker
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=lld"]
```

### ✅ CORRECT: Strategic Inlining for Hot Path

```rust
// Profiling data: process_item() called 1M times/sec, consumes 15% CPU time
// Hot path identified: main -> batch_processor -> process_item

/// Process a single item with minimal overhead
///
/// INLINING RATIONALE (2025-01-30):
/// - Function is small (3 LOC)
/// - Called 1M times/sec (hot path)
/// - Cross-crate calls prevent auto-inlining
/// - Profiling shows 15% CPU time
#[inline]
pub fn process_item(item: &Item) -> u32 {
    item.value.wrapping_mul(item.multiplier).wrapping_add(item.offset)
}

// For rarely executed code paths, use #[cold] to move them out of the hot path
#[cold]
fn handle_error() {
    // ...
}

// Validation: After adding #[inline], CPU time reduced to 8% (46% improvement)
```

### ✅ CORRECT: SIMD for Data-Parallel Operations

```rust
#![feature(portable_simd)]
use std::simd::prelude::*;

/// Sum array of f32 using SIMD (8 elements per instruction)
///
/// PERFORMANCE (2025-01-30):
/// - Input: 1M element array
/// - Scalar implementation: 2.3ms
/// - SIMD implementation: 0.4ms (5.75x speedup)
/// - Hardware: AVX2 (8x f32 lanes)
pub fn sum_f32_simd(values: &[f32]) -> f32 {
    const LANES: usize = 8;
    let (chunks, remainder) = values.as_chunks::<LANES>();

    // Process 8 floats per iteration
    let sum_vector: f32x8 = chunks
        .iter()
        .map(|chunk| f32x8::from_array(*chunk))
        .fold(f32x8::splat(0.0), |acc, v| acc + v);

    sum_vector.reduce_sum() + remainder.iter().sum::<f32>()
}

// Compiler auto-vectorizes simple cases (fallback if portable_simd unavailable)
pub fn sum_f32_auto_vectorized(values: &[f32]) -> f32 {
    values.iter().sum() // LLVM auto-vectorizes this
}
```

### ✅ CORRECT: Const Evaluation for Compile-Time Computation

```rust
// Lookup table generated at compile-time (zero runtime cost)
const fn generate_crc_table() -> [u32; 256] {
    let mut table = [0u32; 256];
    let mut i = 0;
    while i < 256 {
        let mut crc = i as u32;
        let mut j = 0;
        while j < 8 {
            crc = if crc & 1 == 1 {
                (crc >> 1) ^ 0xEDB88320
            } else {
                crc >> 1
            };
            j += 1;
        }
        table[i] = crc;
        i += 1;
    }
    table
}

// Evaluated at compile-time (no runtime cost)
const CRC_TABLE: [u32; 256] = generate_crc_table();

pub fn crc32(data: &[u8]) -> u32 {
    let mut crc = 0xFFFFFFFF_u32;
    for &byte in data {
        let index = ((crc ^ byte as u32) & 0xFF) as usize;
        crc = (crc >> 8) ^ CRC_TABLE[index]; // Table lookup (compile-time generated)
    }
    !crc
}
```

### ✅ CORRECT: Zero-Cost Abstraction with Generics

```rust
// Generic trait (static dispatch, monomorphized, inlined)
pub trait Processor {
    fn process(&self, item: &Item) -> u32;
}

struct FastProcessor;
impl Processor for FastProcessor {
    #[inline]
    fn process(&self, item: &Item) -> u32 {
        item.value * 2
    }
}

// Generic function (zero-cost abstraction)
#[inline]
pub fn process_batch<P: Processor>(items: &[Item], processor: &P) -> Vec<u32> {
    items.iter().map(|item| processor.process(item)).collect()
    // Compiler monomorphizes: generates specialized version for each P type
    // FastProcessor::process inlined into loop (no function call overhead)
}

// Usage: Fully optimized, no abstraction overhead
let processor = FastProcessor;
let results = process_batch(&items, &processor); // Inlined, no vtable
```

### ❌ INCORRECT: Missing Release Profile Configuration

```toml
# Cargo.toml - WRONG: No release profile configuration
# Uses default: opt-level = 3, lto = false, codegen-units = 16

[package]
name = "my-server"
version = "0.1.0"

# Result: 40% slower runtime due to:
# - No cross-crate inlining (lto = false)
# - Suboptimal code generation (codegen-units = 16)
# - No panic abort optimization

# CORRECT: Explicit release profile
[profile.release]
opt-level = 3
lto = "thin"  # At minimum, enable thin LTO
codegen-units = 1
panic = "abort"
```

### ❌ INCORRECT: Dynamic Dispatch in Hot Path

```rust
// WRONG: Trait object (dynamic dispatch) in hot path
pub fn process_batch_dynamic(items: &[Item], processor: &dyn Processor) -> Vec<u32> {
    items.iter().map(|item| processor.process(item)).collect()
    // Every iteration: vtable lookup (cannot inline)
    // Profiling shows 25% CPU time spent in dynamic dispatch overhead
}

// Profiling data (2025-01-30):
// - Dynamic dispatch version: 2.8ms
// - Generic version: 0.6ms (4.6x faster)
// - Root cause: Vtable indirection prevents inlining

// CORRECT: Generic (static dispatch)
pub fn process_batch<P: Processor>(items: &[Item], processor: &P) -> Vec<u32> {
    items.iter().map(|item| processor.process(item)).collect()
    // Monomorphized, inlined, zero vtable overhead
}
```

### ❌ INCORRECT: Runtime Computation of Compile-Time Constants

```rust
// WRONG: Computing lookup table at runtime
pub struct Crc32 {
    table: [u32; 256],
}

impl Crc32 {
    pub fn new() -> Self {
        let mut table = [0u32; 256];
        // Runtime computation (wasted CPU cycles on every instantiation)
        for i in 0..256 {
            let mut crc = i as u32;
            for _ in 0..8 {
                crc = if crc & 1 == 1 {
                    (crc >> 1) ^ 0xEDB88320
                } else {
                    crc >> 1
                };
            }
            table[i] = crc;
        }
        Self { table }
    }
}

// CORRECT: Compile-time computation with const fn
const CRC_TABLE: [u32; 256] = generate_crc_table(); // Computed at compile-time

pub struct Crc32;
impl Crc32 {
    pub const fn new() -> Self {
        Self // No runtime cost
    }

    pub fn compute(&self, data: &[u8]) -> u32 {
        // Use pre-computed table (zero runtime computation cost)
        compute_crc32(data, &CRC_TABLE)
    }
}
```

---

## Related Rules

- **rust-profiling-analysis.md**: Profile before applying optimizations - measure impact quantitatively
- **rust-benchmarking.md**: Benchmark optimizations with Criterion to validate performance improvements
- **rust-memory-optimization.md**: Combine compiler optimizations with memory layout optimizations for maximum performance
