---
description: "Enforce best practices for unsafe block usage, raw pointer operations, and basic FFI patterns in Rust to prevent Undefined Behavior."
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-safety-guarantees.md"
  - "./rust-ffi-integration.md"
  - "./rust-soundness-verification.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Unsafe Code Patterns

## Cohesion Principle

**Why these aspects belong together:** Unsafe patterns—including `unsafe` blocks, raw pointers, and basic FFI—represent the foundational mechanisms for low-level programming in Rust. They share the common property of bypassing Rust's static safety guarantees and require disciplined use. Understanding `unsafe` block discipline naturally extends to raw pointer manipulation, which is a prerequisite for basic FFI operations. These concepts form the tactical layer of `unsafe` Rust, representing the concrete patterns engineers use when interfacing with hardware, operating systems, or C libraries.

## Description

The `unsafe` keyword in Rust provides an escape hatch to perform a small number of operations that the compiler cannot statically prove are safe. These "unsafe superpowers" are:

1. Dereferencing a raw pointer.
2. Calling an `unsafe` function or method (including FFI).
3. Accessing or modifying a mutable `static` variable.
4. Implementing an `unsafe` trait.
5. Accessing fields of a `union`.

The primary reason these operations are gated behind `unsafe` is that their misuse can lead to **Undefined Behavior (UB)**. This rule enforces best practices for using `unsafe` blocks, manipulating raw pointers, and implementing basic FFI patterns to ensure that `unsafe` code is used correctly and does not introduce UB.

**Key Principle:** `unsafe` code must be minimal, well-documented, and wrapped in safe abstractions that uphold Rust's safety guarantees at public API boundaries.

## Rule

### 1. Unsafe Block Organization

**Minimize Unsafe Scope:**

- Keep `unsafe` blocks as small as possible, ideally containing only a single `unsafe` operation.
- Extract `unsafe` operations into small, private helper functions that can be more easily audited.
- Never expose an `unsafe fn` in a public API unless it is impossible to create a safe abstraction.

**Documentation Requirements:**

- Every `unsafe` block MUST have a `// Safety:` comment on the preceding line, explaining the invariants that make the operation safe.
- This comment should justify *why* the code inside the block is safe in its specific context.

```rust
// ✅ CORRECT: Minimal scope and clear safety comment.
let mut data = [1, 2, 3];
let ptr = data.as_mut_ptr();
let len = data.len();

unsafe {
    // Safety: The pointer is valid for `len` elements.
    let slice = std::slice::from_raw_parts_mut(ptr, len);
    slice.sort();
}
```

### 2. Raw Pointer Operations

**Pointer Creation and Conversion:**

- Use `&T as *const T` or `&mut T as *mut T` for simple conversions.
- Use `std::ptr::addr_of!` and `std::ptr::addr_of_mut!` to get pointers to fields of packed structs without creating an intermediate reference.

**Pointer Dereferencing:**

- **ALWAYS** check if a pointer is null using `.is_null()` before dereferencing.
- Ensure the pointer is properly aligned for the type `T` before reading or writing.
- Use `ptr.read()` and `ptr.write()` for potentially unaligned or overlapping memory. These methods avoid creating a reference, which has strict aliasing rules.

**Pointer Arithmetic:**

- Use the `.offset()` or `.add()` methods for pointer arithmetic, and **always** perform bounds checks.
- Creating an out-of-bounds pointer, even if not dereferenced, can be UB in some cases. Use `.wrapping_add()` if you need to perform arithmetic that might wrap.

### 3. Basic FFI Patterns

**`extern "C"` Functions:**

- Use `#[no_mangle]` on functions that will be called from C to prevent name mangling.
- Always validate pointer arguments from C for null before use.
- Return error codes or sentinel values (e.g., `-1`, `NULL`) to signal failure, as panicking across an FFI boundary is UB unless using a `"C-unwind"` ABI.

**`#[repr(C)]` Types:**

- **ALWAYS** use `#[repr(C)]` on structs and enums that are passed across an FFI boundary to ensure a C-compatible memory layout.
- Avoid using Rust-specific types like `String`, `Vec`, `Box`, or `&T` with `#[repr(Rust)]` in FFI function signatures.

## Implementation

- **Clippy Lints**:
  - `clippy::missing_safety_doc`: Enforces that `unsafe` functions have a `# Safety` documentation block.
  - `clippy::undocumented_unsafe_blocks`: Suggests adding comments to explain `unsafe` blocks.
  - `clippy::not_unsafe_ptr_arg_deref`: Checks for dereferencing raw pointers in safe functions.
  - `clippy::cast_ptr_alignment`: Checks for potential pointer misalignment.
- **Runtime Verification**:
  - Use `debug_assert!` to check pointer validity and other invariants in debug builds.
  - Use Miri to run your test suite and detect many kinds of UB at runtime.

## Benefits

- **Clarity and Auditability**: Small, well-documented `unsafe` blocks are easier to review for correctness.
- **Reduced Risk of UB**: Following these patterns helps prevent common `unsafe` pitfalls that lead to Undefined Behavior.
- **Safe Abstractions**: Encapsulating `unsafe` details within a safe API is the cornerstone of idiomatic Rust.

## References

- [The Rustonomicon: What Unsafe Can Do](https://doc.rust-lang.org/nomicon/what-unsafe-does.html)
- [The Rustonomicon: Data Layout](https://doc.rust-lang.org/nomicon/data.html)
- [The Rust Reference: Undefined Behavior](https://doc.rust-lang.org/reference/behavior-considered-undefined.html)
