---
title: "Rust Performance and Optimization Best Practices"
description: "Enforce best practices for performance optimization in Rust code including memory management, zero-cost abstractions, and iterator usage"
category: "rust"
version: "1.0.0"
status: "deprecated"
deprecated: true
deprecated_date: "2025-01-30"
replacement_rules:
  - "./rust-profiling-analysis.md"
  - "./rust-optimization-techniques.md"
  - "./rust-benchmarking.md"
  - "./rust-memory-optimization.md"
globs: ["**/*.rs"]
alwaysApply: false
---

## ⚠️ DEPRECATION NOTICE

**Status**: DEPRECATED as of 2025-01-30

**Reason**: This rule has been split into 4 specialized, cohesive rules for better organization and maintainability:

1. **rust-profiling-analysis.md** - Profiling tools, bottleneck identification, performance analysis
2. **rust-optimization-techniques.md** - Compiler optimizations, inlining, SIMD, const evaluation
3. **rust-benchmarking.md** - Criterion benchmarks, statistical analysis, regression detection
4. **rust-memory-optimization.md** - Allocation patterns, memory layout, cache efficiency

**Migration**: Use the specialized rules above for specific optimization concerns. Content below is preserved for reference but no longer enforced.

---

## Description (PRESERVED FOR REFERENCE)

This rule enforces best practices for performance optimization in Rust code.

## Rule

- **Pattern**: `*.rs`
- **Severity**: Warning
- **Category**: Performance

## Checks

1. **Memory Management**
   - Use stack allocation when possible
   - Avoid unnecessary heap allocations
   - Use appropriate collection types (e.g., `Vec` vs `LinkedList`)
   - Implement proper memory reuse

2. **Zero-Cost Abstractions**
   - Leverage compile-time optimizations
   - Use generics for zero-cost abstractions
   - Avoid runtime overhead in hot paths
   - Use const generics where appropriate

3. **Iterator Usage**
   - Use iterator combinators instead of loops
   - Chain iterator operations efficiently
   - Avoid collecting into intermediate collections
   - Use appropriate iterator adapters

4. **Benchmarking**
   - Use `criterion` for benchmarking
   - Profile code with `perf` or `flamegraph`
   - Measure before optimizing
   - Track performance regressions

## Examples

### Good

```rust
// Efficient iterator usage
let sum: i32 = numbers
    .iter()
    .filter(|&x| x > &0)
    .map(|x| x * x)
    .sum();

// Zero-cost abstraction
fn process<T: AsRef<str>>(input: T) {
    // Generic function with no runtime overhead
    let s = input.as_ref();
}

// Efficient memory usage
struct EfficientBuffer {
    data: Vec<u8>,
    capacity: usize,
}

impl EfficientBuffer {
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            data: Vec::with_capacity(capacity),
            capacity,
        }
    }

    pub fn reuse(&mut self) {
        // Reuse the buffer instead of reallocating
        self.data.clear();
    }
}
```

### Bad

```rust
// Inefficient memory usage
let mut vec = Vec::new();
for i in 0..1000 {
    vec.push(i.to_string()); // Unnecessary heap allocations
}

// Inefficient iterator usage
let result: Vec<_> = numbers
    .iter()
    .filter(|&x| x > &0)
    .collect(); // Unnecessary intermediate collection
let sum: i32 = result.iter().sum();

// Runtime overhead in hot path
fn process_dynamic(input: &dyn AsRef<str>) {
    // Dynamic dispatch in hot path
    let s = input.as_ref();
}
```

## Implementation

Cursor IDE and profiling tools should enforce these practices through:

- Detection of unnecessary heap allocations in hot paths
- Analysis of iterator chain efficiency
- Validation of appropriate collection type usage
- Checking for dynamic dispatch in performance-critical code
- Integration with benchmarking tools like criterion

## Benefits

Performance optimization practices ensure:

- **Efficient resource utilization**: Stack allocation and buffer reuse minimize memory pressure
- **Minimal runtime overhead**: Zero-cost abstractions and compile-time optimizations eliminate unnecessary work
- **Scalable applications**: Iterator combinators and efficient data structures enable high throughput
- **Better user experience**: Fast response times improve perceived application quality
- **Cost reduction**: Lower resource usage reduces infrastructure costs in production

## References

- [Rust Performance Book](https://nnethercote.github.io/perf-book)
- [Criterion Documentation](https://docs.rs/criterion/latest/criterion)
- [Rust Iterator Documentation](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
