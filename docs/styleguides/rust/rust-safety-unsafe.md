---
title: "Rust Safety and Unsafe Code Best Practices"
description: "⚠️ DEPRECATED - Split into 4 specialized rules for better cohesion"
globs: ["**/*.rs"]
alwaysApply: false
deprecated: true
deprecated_date: "2025-01-30"
replacement_rules:
  - rust-unsafe-patterns.md
  - rust-safety-guarantees.md
  - rust-ffi-integration.md
  - rust-soundness-verification.md
---

## ⚠️ DEPRECATION NOTICE

**Status:** DEPRECATED as of 2025-01-30

**Reason:** This rule has been split into 4 cohesive, specialized rules for better organization and maintainability.

**Migration Path:**

- For unsafe block patterns and raw pointers → Use `rust-unsafe-patterns.md`
- For safety contracts and invariants → Use `rust-safety-guarantees.md`
- For C FFI and binding generation → Use `rust-ffi-integration.md`
- For Miri testing and verification → Use `rust-soundness-verification.md`

**Original content preserved below for reference:**

---

## Description

This rule enforces best practices for safe and unsafe code in Rust.

## Rule

- **Pattern**: `*.rs`
- **Severity**: Error
- **Category**: Safety

## Checks

1. **Unsafe Code Organization**
   - Minimize unsafe code blocks
   - Document unsafe invariants
   - Use safe abstractions over unsafe code
   - Implement safe public APIs

2. **FFI Safety**
   - Use `#[repr(C)]` for C-compatible types
   - Document FFI safety requirements
   - Handle null pointers safely
   - Use `extern "C"` for C ABI functions

3. **Memory Safety**
   - Document memory ownership
   - Use `ManuallyDrop` when needed
   - Implement `Drop` for cleanup
   - Handle uninitialized memory safely

4. **Thread Safety**
   - Document thread safety guarantees
   - Use `Send` and `Sync` appropriately
   - Handle concurrent access safely
   - Use atomic operations when needed

## Examples

### Good

```rust
/// A safe wrapper around an unsafe FFI type.
///
/// # Safety
///
/// This type maintains the following invariants:
/// - The inner pointer is always valid
/// - The inner pointer is never null
/// - The inner pointer is properly aligned
pub struct SafeWrapper {
    inner: *mut ffi::UnsafeType,
}

impl SafeWrapper {
    /// Creates a new safe wrapper.
    ///
    /// # Safety
    ///
    /// The caller must ensure that:
    /// - The pointer is valid and properly aligned
    /// - The pointer is not null
    /// - The pointer will remain valid for the lifetime of the wrapper
    pub unsafe fn new(ptr: *mut ffi::UnsafeType) -> Self {
        assert!(!ptr.is_null(), "Pointer must not be null");
        Self { inner: ptr }
    }

    /// Safely accesses the inner value.
    pub fn get_value(&self) -> u32 {
        unsafe {
            // Safety: We maintain the invariant that inner is valid
            ffi::get_value(self.inner)
        }
    }
}

impl Drop for SafeWrapper {
    fn drop(&mut self) {
        unsafe {
            // Safety: We maintain the invariant that inner is valid
            ffi::destroy(self.inner);
        }
    }
}

/// A thread-safe counter using atomic operations.
pub struct AtomicCounter {
    count: AtomicU64,
}

impl AtomicCounter {
    pub fn new() -> Self {
        Self {
            count: AtomicU64::new(0),
        }
    }

    pub fn increment(&self) -> u64 {
        self.count.fetch_add(1, Ordering::SeqCst)
    }
}
```

### Bad

```rust
// Bad: Unsafe code without documentation
pub unsafe fn process(ptr: *mut u8) {
    *ptr = 42;
}

// Bad: Missing safety invariants
pub struct UnsafeWrapper {
    inner: *mut ffi::UnsafeType,
}

// Bad: Unsafe FFI without proper null checks
pub extern "C" fn bad_ffi(ptr: *const u8) -> u32 {
    unsafe { *ptr }
}
```

## Implementation

Cursor IDE and clippy should enforce these practices through:

- Detection of undocumented unsafe blocks
- Validation of safety invariant documentation
- Checking for proper FFI null pointer handling
- Analysis of thread safety markers (Send/Sync)
- Warning on unsafe abstractions without safe public APIs

## Benefits

Proper safety practices ensure:

- **Memory safety guarantees**: Documented invariants prevent memory corruption
- **Thread safety**: Send/Sync markers enable safe concurrency
- **FFI safety**: Proper C ABI handling prevents undefined behavior
- **Clear safety boundaries**: Safe wrappers contain unsafe code complexity
- **Audit trail**: Safety documentation enables security review

## References

- [Rust Book - Unsafe Rust](https://doc.rust-lang.org/book/ch19-01-unsafe-rust.html)
- [Rust Reference - FFI](https://doc.rust-lang.org/reference/items/external-blocks.html)
- [Rustonomicon](https://doc.rust-lang.org/nomicon)
