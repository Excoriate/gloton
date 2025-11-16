---
description: "Enforce systematic profiling practices using cargo flamegraph, perf, and other profiling tools to identify performance bottlenecks and hot paths in Rust code"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - "./rust-benchmarking.md"
  - "./rust-optimization-techniques.md"
  - "./rust-memory-optimization.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

## Cohesion Principle

**WHY These Aspects Belong Together:**

Profiling analysis forms a unified diagnostic workflow where tool selection, bottleneck identification, and performance analysis work synergistically. cargo flamegraph visualizes CPU time distribution, perf captures hardware events, valgrind tracks memory behavior - these tools produce complementary insights that converge on the same goal: identifying WHERE performance problems exist. Hot path identification reveals which code paths consume the most resources, call graph analysis shows HOW functions interact to create bottlenecks, and systematic profiling methodology ensures REPRODUCIBLE measurements. Separating these concepts would fragment the diagnostic process - choosing profiling tools without understanding bottleneck identification produces meaningless data, while analyzing call graphs without systematic methodology leads to unreliable conclusions.

---

## Description

Systematic profiling is the foundation of performance optimization in Rust. This rule enforces the use of appropriate profiling tools (cargo flamegraph, perf, valgrind), structured bottleneck identification methodologies, and rigorous performance analysis practices to pinpoint performance-critical code paths before optimization. Profiling transforms speculation into evidence-based optimization decisions.

---

## Rule

### 1. Always Profile Before Optimizing

**MANDATORY**: Never optimize based on intuition - measure with profiling tools first.

**Profiling Tool Selection:**
- **cargo flamegraph**: CPU profiling with visual flame graphs (default for CPU bottlenecks)
- **perf**: Hardware event profiling (cache misses, branch mispredictions, IPC)
- **valgrind**: Memory profiling (heap allocations, leaks, cache simulation)
- **heaptrack**: Heap memory profiling with allocation traces
- **samply**: A low-overhead, easy-to-use sampling profiler, great for production environments.

**Detection**: Code optimization without prior profiling data is prohibited.

### 2. Identify Hot Paths with Statistical Significance

**MANDATORY**: Focus optimization on code paths consuming >5% of total execution time.

**Hot Path Identification:**
```bash
# Generate flame graph
cargo flamegraph --bin your_binary

# Identify functions consuming >5% of samples
# Read flame graph: width = time spent (wider = hotter)
```

**Statistical Threshold**: Functions appearing in <5% of samples are noise - profile-guided optimization (PGO) focuses on high-impact targets.

**Detection**: Optimizing cold paths (< 5% time) without hot path analysis first.

### 3. Use perf for Hardware-Level Analysis

**MANDATORY**: When CPU bottlenecks are identified, analyze hardware events with perf.

**Critical Hardware Events:**
```bash
# Cache miss analysis
perf stat -e cache-references,cache-misses ./target/release/binary

# Branch prediction analysis
perf stat -e branches,branch-misses ./target/release/binary

# Instructions per cycle (IPC < 1.0 indicates stalls)
perf stat -e instructions,cycles ./target/release/binary

# Full event recording with call graph
perf record -g ./target/release/binary
perf report
```

**Interpretation:**
- **High cache misses**: Memory layout issues (see rust-memory-optimization.md)
- **High branch misses**: Unpredictable control flow (consider branch prediction hints)
- **Low IPC**: CPU pipeline stalls (check dependencies, memory latency)

**Detection**: CPU optimization without hardware event analysis.

### 4. Analyze Call Graphs for Unexpected Overhead

**MANDATORY**: Examine call graphs to identify unexpected function call overhead.

**Call Graph Analysis:**
```bash
# Generate call graph with perf
perf record --call-graph dwarf ./target/release/binary
perf report --stdio --no-children

# Look for:
# - Deep call stacks (function call overhead)
# - Unexpected allocations in hot paths (Vec::push, Box::new)
# - Dynamic dispatch (dyn Trait) in hot paths
```

**Red Flags in Call Graphs:**
- Allocation functions (`alloc::alloc`, `Vec::grow`) in hot paths
- Dynamic dispatch (`<dyn Trait>::method`) in tight loops
- Deep recursion with no tail call optimization
- Small functions not inlined (missing `#[inline]`)

**Detection**: Optimization without call graph inspection.

### 5. Profile in Release Mode with Debug Symbols

**MANDATORY**: Always profile optimized release builds with debug symbols for accurate results.

**Cargo Configuration:**
```toml
# Cargo.toml
[profile.release]
debug = "line-tables-only"  # Enable line number debug info for profiling
force-frame-pointers = true # For better stack traces
```

**Note on Symbol Demangling**: If your profiler output shows mangled Rust symbols, use `rustfilt` to demangle them, or compile with `-C symbol-mangling-version=v0` for simpler symbols.

**Reasoning**: Debug builds have different performance characteristics (no inlining, bounds checking). Release builds with debug symbols provide accurate profiling data while maintaining optimization.

**Detection**: Profiling debug builds or release builds without debug symbols.

### 6. Document Profiling Findings Before Optimization

**MANDATORY**: Record profiling results (flame graphs, perf stats, bottleneck locations) before making changes.

**Documentation Template:**
```rust
// Performance Profile (YYYY-MM-DD)
// Profiling tool: cargo flamegraph
// Bottleneck: compute_intensive() consumes 45% CPU time
// Hot path: main -> process_batch -> compute_intensive
// Hardware events: 23% cache miss rate (perf stat)
// Optimization target: Reduce cache misses via memory layout changes

fn compute_intensive(data: &[u8]) -> u32 {
    // Implementation
}
```

**Detection**: Code changes claiming "performance improvement" without documented profiling baseline.

---

## Implementation

Cursor IDE and profiling tools should enforce these practices through:

**Automated Profiling Integration:**
- Detect optimization commits (keywords: "optimize", "performance", "faster")
- Require profiling data attachment (flame graph, perf report) in commit message or PR
- Flag optimization without baseline measurements

**Profiling Tool Validation:**
- Verify `cargo flamegraph` installation: `cargo install flamegraph`
- Check `perf` availability on Linux: `which perf`
- Validate `Cargo.toml` has `[profile.release] debug = true`

**Hot Path Analysis:**
- Parse flame graph SVG to extract function time percentages
- Identify functions with >5% time consumption
- Generate hot path report sorted by time

**Call Graph Inspection:**
- Parse `perf report` output for dynamic dispatch patterns
- Detect allocation functions in hot paths
- Flag deep call stacks (>10 levels) in performance-critical code

---

## Benefits

Systematic profiling analysis ensures:

- **Evidence-Based Optimization**: Profiling data eliminates speculation - optimize what's measured, not what's guessed
- **High-Impact Changes**: Focusing on hot paths (>5% time) maximizes optimization ROI - 80/20 rule applied
- **Hardware-Aware Development**: perf analysis reveals cache misses, branch mispredictions - optimize for CPU architecture
- **Reproducible Performance Improvements**: Documented baselines enable before/after comparison - quantify gains objectively
- **Efficient Engineering Time**: Avoid wasted effort on cold paths - profile-guided optimization focuses on bottlenecks

---

## Examples

### ✅ CORRECT: Systematic Profiling Before Optimization

```rust
// Step 1: Profile with cargo flamegraph
// $ cargo flamegraph --bin data_processor
// Result: process_records() consumes 62% CPU time

// Step 2: Analyze with perf
// $ perf stat -e cache-misses ./target/release/data_processor
// Result: 31% cache miss rate (high!)

// Step 3: Document baseline
/// Performance Profile (2025-01-30)
/// Profiling tool: cargo flamegraph + perf stat
/// Bottleneck: process_records() consumes 62% CPU time
/// Hardware events: 31% cache miss rate
/// Hot path: main -> batch_process -> process_records
/// Root cause: Random memory access pattern (hash lookups)
/// Optimization strategy: Replace HashMap with sorted Vec for cache locality
pub fn process_records(records: &[Record], lookup: &HashMap<u32, String>) -> Vec<String> {
    records
        .iter()
        .map(|r| lookup.get(&r.id).cloned().unwrap_or_default())
        .collect()
}

// Step 4: Optimize based on profiling data
/// Performance Profile (2025-01-30) - OPTIMIZED
/// Change: Replaced HashMap with sorted Vec + binary search
/// Result: Cache miss rate reduced to 8%, process_records() now 21% CPU time (3x improvement)
/// Validation: cargo flamegraph confirms 41% CPU time reduction
pub fn process_records_optimized(records: &[Record], lookup: &[(u32, String)]) -> Vec<String> {
    records
        .iter()
        .map(|r| {
            lookup
                .binary_search_by_key(&r.id, |(k, _)| *k)
                .ok()
                .map(|idx| lookup[idx].1.clone())
                .unwrap_or_default()
        })
        .collect()
}
```

### ✅ CORRECT: Call Graph Analysis Reveals Dynamic Dispatch

```bash
# Step 1: Generate call graph with perf
$ perf record --call-graph dwarf ./target/release/processor
$ perf report --stdio --no-children

# Output shows:
# 45.23%  processor  [.] <dyn MyTrait>::process
# 12.11%  processor  [.] alloc::alloc
# 8.76%   processor  [.] process_batch

# Analysis: Dynamic dispatch (<dyn MyTrait>) in hot path consumes 45% time
```

```rust
// BEFORE: Dynamic dispatch in hot path
pub fn process_batch(items: &[Box<dyn MyTrait>]) {
    for item in items {
        item.process(); // Dynamic dispatch overhead
    }
}

// AFTER: Static dispatch with enum
pub enum ProcessorType {
    TypeA(TypeAProcessor),
    TypeB(TypeBProcessor),
}

impl ProcessorType {
    pub fn process(&self) {
        match self {
            Self::TypeA(p) => p.process(), // Static dispatch
            Self::TypeB(p) => p.process(),
        }
    }
}

pub fn process_batch_optimized(items: &[ProcessorType]) {
    for item in items {
        item.process(); // Static dispatch via match - no vtable lookup
    }
}

// Validation: perf report shows ProcessorType::process now 12% time (73% reduction)
```

### ❌ INCORRECT: Optimization Without Profiling

```rust
// WRONG: Assumed string concatenation was bottleneck without profiling
// Changed from String to Cow<'static, str> based on intuition
// Result: No measurable improvement - actual bottleneck was elsewhere

pub fn format_output(data: &[Record]) -> String {
    // Premature optimization: Cow adds complexity without evidence
    let prefix: Cow<'static, str> = Cow::Borrowed("Result: ");
    data.iter()
        .map(|r| format!("{}{}", prefix, r.value))
        .collect::<Vec<_>>()
        .join(", ")
}

// Should have profiled first:
// cargo flamegraph would show format!() consumes <2% time
// Real bottleneck: data.iter().map().collect().join() pattern (allocates intermediate Vec)
```

### ❌ INCORRECT: Profiling Debug Build

```bash
# WRONG: Profiling unoptimized debug build
$ cargo build
$ cargo flamegraph --bin processor

# Result: Misleading flame graph showing Vec bounds checking overhead
# Debug builds have different performance characteristics (no inlining, bounds checking)
# Cannot extrapolate debug profile to release performance

# CORRECT: Profile release build with debug symbols
$ cargo flamegraph --release --bin processor
# (Ensure Cargo.toml has [profile.release] debug = true)
```

### ❌ INCORRECT: Ignoring Hardware Events

```rust
// WRONG: Optimized for algorithmic complexity (O(n) -> O(log n))
// but ignored hardware-level cache behavior

// Used HashMap for O(1) lookups
pub fn lookup_values(ids: &[u32], map: &HashMap<u32, String>) -> Vec<String> {
    ids.iter().map(|id| map.get(id).cloned().unwrap()).collect()
}

// Result: High cache miss rate (random memory access via hash)
// perf stat shows: 42% cache miss rate

// Should have analyzed hardware events:
// perf stat -e cache-misses would reveal cache thrashing
// Sorted Vec with binary search (O(log n)) has better cache locality
// Result: 7% cache miss rate - faster despite worse big-O complexity
```

---

## Related Rules

- **rust-benchmarking.md**: Criterion benchmarks for quantifying optimization impact (measure improvements)
- **rust-optimization-techniques.md**: Apply compiler optimizations, inlining, SIMD after profiling identifies bottlenecks
- **rust-memory-optimization.md**: Optimize memory layout, allocation patterns based on profiling findings
