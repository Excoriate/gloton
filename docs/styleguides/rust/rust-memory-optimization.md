---
description: "Enforce memory-efficient patterns including stack allocation, memory layout optimization, cache-friendly data structures, and allocation pattern optimization for minimal memory overhead and maximum cache efficiency"
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-profiling-analysis.md"
  - "./rust-optimization-techniques.md"
  - "./rust-benchmarking.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Memory Optimization Best Practices

## Cohesion Principle

**Why These Aspects Belong Together:**

Memory optimization forms a unified performance strategy where allocation patterns, memory layout, and cache efficiency work synergistically to minimize memory overhead and maximize CPU efficiency. Stack allocation eliminates heap management overhead (malloc/free), memory layout optimization (`#[repr]`, field ordering) reduces struct size and improves cache line utilization, cache efficiency techniques (data locality, false sharing avoidance) exploit the CPU cache hierarchy, appropriate collection type selection balances access patterns with memory footprint, and buffer reuse strategies eliminate redundant allocations. These concepts are interdependent: stack allocation benefits from compact memory layout (fits in cache lines), cache efficiency requires data locality which depends on memory layout, and buffer reuse is most effective when buffers are correctly sized and aligned. Together, they form a complete memory optimization methodology: allocate efficiently → lay out compactly → access cache-friendly → reuse strategically.

---

## Description

Memory optimization in Rust targets three performance dimensions: allocation overhead (heap vs stack), memory layout efficiency (struct size, alignment, padding), and cache utilization (locality, false sharing). This rule enforces stack allocation where feasible, memory layout optimization through `#[repr]` attributes and field ordering, cache-efficient data structures and access patterns, appropriate collection type selection based on usage patterns, and buffer reuse strategies to eliminate redundant allocations - collectively minimizing memory footprint and maximizing cache hit rates.

---

## Rule

### 1. Prefer Stack Allocation Over Heap Allocation

**MANDATORY**: Use stack allocation (arrays, fixed-size structs) for data with known, bounded size. Reserve heap allocation (Vec, Box, String) for dynamically-sized data.

**Stack vs Heap Tradeoffs:**
```rust
// ✅ STACK: Known size, short lifetime, frequently accessed
fn process_small_buffer(input: &[u8]) -> [u8; 64] {
    let mut buffer = [0u8; 64]; // Stack-allocated (fast)
    buffer[..input.len()].copy_from_slice(input);
    buffer
}

// ❌ HEAP: Unnecessary allocation for fixed-size buffer
fn process_small_buffer_heap(input: &[u8]) -> Vec<u8> {
    let mut buffer = vec![0u8; 64]; // Heap-allocated (slower)
    buffer[..input.len()].copy_from_slice(input);
    buffer
}
```

### 2. Optimize Struct and Enum Memory Layout

**MANDATORY**: Control memory layout to reduce size and improve cache efficiency.

**Field Ordering and `#[repr(C)]`**:
Order fields from largest to smallest to minimize padding. Use `#[repr(C)]` for FFI or when a specific layout is required.

```rust
// Default layout (suboptimal)
struct Unoptimized {
    flag: bool,      // 1 byte + 7 padding
    value: u64,      // 8 bytes
    count: u32,      // 4 bytes + 4 padding
} // Total: 24 bytes

// Optimized layout
#[repr(C)]
struct Optimized {
    value: u64,      // 8 bytes
    count: u32,      // 4 bytes
    flag: bool,      // 1 byte + 3 padding
} // Total: 16 bytes (33% size reduction)
```

**Boxing Large Enum Variants**:
If an enum has a variant that is much larger than the others, `Box` its contents to reduce the enum's overall size.

```rust
// Large enum
enum MyEnum {
    Small,
    Large([u8; 1024]), // This makes the whole enum large
}

// Optimized enum
enum MyOptimizedEnum {
    Small,
    Large(Box<[u8; 1024]>), // Boxed variant
}
```

### 3. Avoid False Sharing with Cache Line Alignment

**MANDATORY**: Align frequently-modified shared data to cache line boundaries (typically 64 bytes) to prevent false sharing in concurrent code.

```rust
use std::sync::atomic::AtomicU64;

// ❌ FALSE SHARING
struct SharedState {
    counter_a: AtomicU64, // Thread A modifies
    counter_b: AtomicU64, // Thread B modifies (same cache line!)
}

// ✅ CACHE LINE ALIGNED
#[repr(align(64))]
struct AlignedCounter(AtomicU64);

struct SharedStateOptimized {
    counter_a: AlignedCounter, // Separate cache line
    counter_b: AlignedCounter, // Separate cache line
}
```

### 4. Choose Collection Types Based on Access Patterns

**MANDATORY**: Select collection types optimized for your specific use case.

| Access Pattern                | Optimal Collection        |
| ----------------------------- | ------------------------- |
| Random access by index        | `Vec<T>`                  |
| Frequent insertions/deletions | `VecDeque<T>`             |
| Key-value lookup              | `HashMap<K, V>`           |
| Ordered iteration             | `BTreeMap<K, V>`          |
| Small, fixed-size collections | `[T; N]` (array)          |
| Small, dynamic collections    | `smallvec::SmallVec`      |
| Immutable, sized collection   | `Box<[T]>`                |

**Convert `Vec<T>` to `Box<[T]>`**:
If a `Vec` will not be resized further, convert it to a `Box<[T]>` to save a word of memory (the capacity field).

```rust
let v: Vec<i32> = (0..100).collect();
let b: Box<[i32]> = v.into_boxed_slice();
// `b` is 2 words, `v` was 3 words
```

### 5. Implement Buffer and Collection Reuse

**MANDATORY**: Reuse existing buffers and collections in loops or hot paths to avoid repeated allocations.

```rust
// ❌ ALLOCATION IN LOOP
fn process_batches_allocating(batches: &[&[u8]]) {
    for batch in batches {
        let mut buffer = Vec::with_capacity(1024); // Allocates every iteration
        // ...
    }
}

// ✅ BUFFER REUSE
fn process_batches_reusing(batches: &[&[u8]]) {
    let mut buffer = Vec::with_capacity(1024); // Single allocation
    for batch in batches {
        buffer.clear(); // Reuse capacity
        // ...
    }
}
```

**Use `clone_from`**:
When cloning collections, `clone_from` can reuse the destination's buffer if it has enough capacity.

```rust
let mut dest = vec![1, 2, 3];
let src = vec![4, 5];
dest.clone_from(&src); // `dest` is now `[4, 5]`, may reuse allocation
```

### 6. Pre-Allocate Capacity for Known-Size Collections

**MANDATORY**: Use `with_capacity()` when the size of a collection is known or can be estimated, to avoid reallocations.

```rust
// ❌ REALLOCATION
let mut vec = Vec::new();
for i in 0..1000 {
    vec.push(i); // Reallocates multiple times
}

// ✅ PRE-ALLOCATED
let mut vec = Vec::with_capacity(1000);
for i in 0..1000 {
    vec.push(i); // No reallocations
}
```

### 7. Use Small String/Vector Optimizations

**MANDATORY**: For frequently-allocated short strings or vectors, use libraries like `smallvec` or `smartstring` to avoid heap allocations.

```rust
use smallvec::SmallVec;
use smartstring::alias::String as SmartString;

// ✅ Stack-allocated for small data
let small_vec: SmallVec<[u8; 16]> = SmallVec::new();
let short_str = SmartString::from("short");
```

### 8. Use `Cow` for Clone-on-Write Scenarios

**MANDATORY**: Use `std::borrow::Cow` when a function can accept either borrowed or owned data, avoiding clones when the data doesn't need to be modified.

```rust
use std::borrow::Cow;

fn process_data(data: Cow<str>) -> Cow<str> {
    if data.contains(' ') {
        // Modify and return owned data
        Cow::Owned(data.replace(' ', "_"))
    } else {
        // No modification, return borrowed data
        data
    }
}
```

### 9. Measure and Validate Memory Usage

**MANDATORY**: Use tools to measure memory usage and validate optimizations.

-   **Measure Type Sizes**: Use `std::mem::size_of::<T>()` and the nightly `RUSTFLAGS="-Zprint-type-sizes"` flag to inspect type layouts.
-   **Profile Heap Allocations**: Use tools like `dhat` or `valgrind --tool=massif` to identify allocation hotspots.
-   **Static Assertions**: Use `static_assertions::assert_eq_size!` to prevent unintentional type size regressions.

## Implementation

-   **Profiling**: Integrate heap profiling tools into your development workflow.
-   **Linting**: Use Clippy lints like `clippy::large_enum_variant` and `clippy::vec_init_then_push`.
-   **Code Review**: Manually inspect hot paths for unnecessary allocations and suboptimal data structures.

## Benefits

-   **Reduced Allocation Overhead**: Faster execution by avoiding costly heap allocations.
-   **Improved Cache Performance**: Better data locality and layout lead to higher cache hit rates.
-   **Lower Memory Footprint**: Smaller data structures and less fragmentation reduce overall memory usage.
-   **Predictable Performance**: Eliminates unpredictable pauses from reallocations.

## References

-   [The Rust Performance Book](https://nnethercote.github.io/perf-book/)
-   [Rustonomicon: Data Layout](https://doc.rust-lang.org/nomicon/data.html)
-   [`dhat-rs` for heap profiling](https://crates.io/crates/dhat)
-   [`smallvec` crate](https://crates.io/crates/smallvec)
-   [`smartstring` crate](https://crates.io/crates/smartstring)