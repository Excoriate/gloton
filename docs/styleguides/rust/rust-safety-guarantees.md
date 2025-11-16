---
description: "Enforce documentation of safety invariants, contracts, and unsafe trait implementation bounds in Rust to prevent Undefined Behavior."
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-unsafe-patterns.md"
  - "./rust-ffi-integration.md"
  - "./rust-soundness-verification.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Safety Guarantees and Invariants

## Cohesion Principle

**Why these aspects belong together:** Safety guarantees in `unsafe` Rust—including invariants, contracts, and trait bounds—form a cohesive system for proving code correctness. Invariants define what must always be true for a type, contracts specify the responsibilities between safe and `unsafe` code, and `unsafe` trait bounds formalize these guarantees at the type level. Together, they create a framework for reasoning about the correctness of `unsafe` code, ensuring that it does not introduce Undefined Behavior.

## Description

The `unsafe` keyword in Rust allows for a small number of operations that the compiler cannot statically verify for memory safety, such as dereferencing raw pointers. While powerful, `unsafe` code shifts the responsibility of upholding Rust's safety guarantees from the compiler to the programmer. Misusing `unsafe` can lead to **Undefined Behavior (UB)**, which can cause unpredictable crashes, security vulnerabilities, or incorrect behavior.

This rule enforces the practice of clearly documenting the **safety invariants** and **contracts** for any `unsafe` code. This documentation is not just for human readers; it serves as a formal specification that allows for auditing, verification, and safe composition of `unsafe` abstractions.

## Rule

### 1. Document Type Invariants

**MANDATORY**: For any type that uses `unsafe` code to maintain its properties, you must document the invariants that the type guarantees.

-   **What to Document**:
    -   Pointer validity (e.g., non-null, aligned, within bounds).
    -   Internal consistency (e.g., `len <= capacity` for a custom vector).
    -   Ownership and aliasing rules.
-   **Where to Document**: In a `/// # Safety` or `/// # Invariants` section in the type's documentation.
-   **Verification**: Use `debug_assert!` to check invariants in debug builds.

```rust
/// A non-empty vector.
///
/// # Invariants
///
/// - The inner vector is never empty (`vec.len() > 0`).
pub struct NonEmptyVec<T> {
    vec: Vec<T>,
}
```

### 2. Specify Clear Safety Contracts for `unsafe` Functions

**MANDATORY**: Every `unsafe` function must have a `# Safety` section in its documentation explaining the contract that callers must uphold.

-   **Preconditions**: What must be true *before* the function is called.
-   **Postconditions**: What the function guarantees will be true *after* it is called.
-   **Invariants**: What remains true *during* the function's execution.

```rust
/// Reads from a buffer at a given offset.
///
/// # Safety
///
/// The caller must ensure that:
/// - `offset` is within the bounds of `buffer`.
/// - `buffer` points to a valid memory block of at least `offset + 1` bytes.
pub unsafe fn read_at_offset(buffer: *const u8, offset: usize) -> u8 {
    // Safety: Caller upholds the contract.
    *buffer.add(offset)
}
```

### 3. Justify `unsafe` Trait Implementations

**MANDATORY**: When implementing an `unsafe` trait like `Send`, `Sync`, or `GlobalAlloc`, you must provide a `# Safety` section explaining why the implementation is sound.

-   **`Send`**: Justify why the type can be safely moved to another thread.
-   **`Sync`**: Justify why the type can be safely shared between threads (i.e., accessed via `&T`).
-   **`GlobalAlloc`**: Justify why the allocator implementation is sound and meets the required invariants (e.g., alignment, non-overlapping memory blocks).

```rust
struct MyRawHandle(*mut u8);

/// # Safety
///
/// `MyRawHandle` is `Send` because the underlying C library that manages the handle
/// is thread-safe.
unsafe impl Send for MyRawHandle {}
```

### 4. Document Memory and Lifetime Contracts

**MANDATORY**: For functions that deal with raw pointers, explicitly document ownership and lifetime semantics.

-   **Ownership**: Specify whether a function takes ownership of a pointer (and is thus responsible for freeing it) or merely borrows it.
-   **Lifetimes**: If a returned reference is derived from an input pointer, explain the lifetime relationship.

```rust
/// Creates a new resource and returns a pointer to it.
///
/// The caller takes ownership of the returned pointer and is responsible
/// for calling `destroy_resource` to free it.
#[no_mangle]
pub extern "C" fn create_resource() -> *mut MyResource;

/// Destroys a resource created by `create_resource`.
///
/// # Safety
///
/// `ptr` must be a valid pointer returned by `create_resource`.
#[no_mangle]
pub unsafe extern "C" fn destroy_resource(ptr: *mut MyResource) {
    // Safety: Caller guarantees the pointer is valid.
    drop(Box::from_raw(ptr));
}
```

## Implementation

-   **Clippy Lints**:
    -   `clippy::missing_safety_doc`: Enforces that all `unsafe` functions and trait implementations have a `# Safety` block.
    -   `clippy::undocumented_unsafe_blocks`: Suggests adding comments to explain the reasoning behind `unsafe` blocks.
-   **Code Review**: Manually audit `unsafe` code to ensure that the documented contracts are sufficient and correctly implemented.

## Benefits

-   **Correctness**: Formal contracts enable rigorous reasoning about the safety of `unsafe` code.
-   **Auditability**: Clear invariants and contracts make security and correctness reviews more effective.
-   **Maintainability**: Documented safety contracts prevent future changes from accidentally violating safety guarantees.
-   **Composability**: Well-specified `unsafe` abstractions can be safely composed into larger, safe systems.

## References

-   [The Rustonomicon: The Dark Arts of Unsafe Rust](https://doc.rust-lang.org/nomicon/index.html)
-   [The Rust Reference: Undefined Behavior](https://doc.rust-lang.org/reference/behavior-considered-undefined.html)