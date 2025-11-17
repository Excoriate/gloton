---
description: "Enforce soundness verification through Miri testing, safety proofs, and formal verification patterns for unsafe Rust code"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - ./rust-unsafe-patterns.md
  - ./rust-safety-guarantees.md
  - ./rust-ffi-integration.md
deprecated: false
globs: ["**/*.rs", "**/.cargo/config.toml"]
alwaysApply: true
---

## Cohesion Principle

**Why these aspects belong together:** Soundness verification (Miri testing, safety proofs, and formal verification) represents the validation layer of unsafe Rust—the empirical and mathematical techniques that prove code correctness. These aspects share the common goal of detecting undefined behavior before production. Miri provides dynamic analysis (runtime UB detection), safety proofs provide static reasoning (contract verification), and formal verification provides mathematical certainty (correctness proofs). Together they form a defense-in-depth verification strategy, progressing from lightweight testing to heavyweight proof.

## Description

This rule enforces rigorous verification practices for unsafe Rust code including Miri testing for undefined behavior detection, safety proof documentation, and formal verification patterns using tools like Kani and Prusti.

**Scope:**

- Miri test suite integration and configuration
- Safety proof documentation and invariant checking
- Formal verification tool integration (Kani, Prusti, Creusot)
- Property-based testing for unsafe code
- Sanitizer integration (AddressSanitizer, ThreadSanitizer)

**Key Principle:** Unsafe code correctness cannot be assumed—it must be verified through multiple independent techniques ranging from dynamic testing to formal proofs.

## Rule

### 1. Miri Testing

**Miri Integration:**

- Add Miri tests for ALL unsafe code paths
- Run Miri in CI for every commit touching unsafe code
- Configure Miri flags for strict checking
- Test edge cases: null pointers, unaligned access, data races

**Miri Configuration (.cargo/config.toml):**

```toml
[target.'cfg(miri)']
runner = "miri"

[build]
rustflags = [
    "-Zmiri-strict-provenance",
    "-Zmiri-symbolic-alignment-check",
    "-Zmiri-disable-isolation", # For FFI testing
]
```

**Test Coverage Requirements:**

- Test all unsafe function entry points
- Exercise boundary conditions (zero-sized types, null pointers)
- Verify thread safety with concurrent test scenarios
- Test FFI interactions with mock C implementations

### 2. Safety Proof Documentation

**Proof Structure:**

```rust
/// # Safety Proof
///
/// Preconditions:
/// - [P1] Caller guarantees X
/// - [P2] Caller guarantees Y
///
/// Invariants:
/// - [I1] Type maintains Z
/// - [I2] Function preserves W
///
/// Verification:
/// - [V1] Miri test: test_unsafe_path
/// - [V2] Property test: proptest_safety_invariant
/// - [V3] Manual review: @reviewer on 2025-01-15
```

**Proof Elements:**

- **Preconditions:** Assumptions that caller must satisfy
- **Invariants:** Properties that remain true throughout execution
- **Postconditions:** Guarantees upon function return
- **Verification:** Evidence supporting safety claims (tests, reviews, proofs)

**Invariant Checking:**

- Use `debug_assert!` to check invariants in debug builds
- Add runtime checks for critical invariants in release builds
- Document when invariants are established and maintained

### 3. Formal Verification Integration

**Kani (Model Checking):**

```rust
#[cfg(kani)]
#[kani::proof]
fn verify_unsafe_operation() {
    let ptr: *mut u8 = kani::any();
    kani::assume(!ptr.is_null());
    kani::assume(ptr as usize % std::mem::align_of::<u8>() == 0);

    unsafe {
        let value = read_validated(ptr);
        // Kani verifies no UB occurs
    }
}
```

**Prusti (Verification with Contracts):**

```rust
#[requires(!ptr.is_null())]
#[requires(ptr as usize % std::mem::align_of::<T>() == 0)]
#[ensures(result == old(*ptr))]
pub unsafe fn read_verified<T: Copy>(ptr: *const T) -> T {
    *ptr
}
```

**Verification Workflow:**

- Add verification proofs for critical unsafe functions
- Run verification tools in CI on unsafe code changes
- Document verification status in function comments

### 4. Property-Based Testing

**Proptest for Unsafe Code:**

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_buffer_safety(
        offset in 0usize..1024,
        len in 1usize..1024,
    ) {
        let buffer = vec![0u8; len];
        let ptr = buffer.as_ptr();

        if offset < len {
            unsafe {
                // Property: Access within bounds never causes UB
                let _ = *ptr.add(offset);
            }
        }
    }
}
```

**Property Selection:**

- Test memory safety: no out-of-bounds access
- Test thread safety: no data races under concurrent load
- Test correctness: invariants hold for all inputs
- Test panic safety: no UB during unwind

### 5. Sanitizer Integration

**AddressSanitizer (Memory Errors):**

```toml
# .cargo/config.toml
[target.x86_64-unknown-linux-gnu]
rustflags = ["-Zsanitizer=address"]
```

**ThreadSanitizer (Data Races):**

```toml
[target.x86_64-unknown-linux-gnu]
rustflags = ["-Zsanitizer=thread"]
```

**Sanitizer Coverage:**

- Run AddressSanitizer on memory-unsafe operations
- Run ThreadSanitizer on concurrent unsafe code
- Add sanitizer runs to CI pipeline
- Document known false positives

## Implementation

Cursor IDE should enforce these practices through:

**Static Analysis:**

- Detect unsafe code without corresponding Miri tests
- Flag missing safety proof documentation
- Identify untested unsafe code paths in coverage reports

**Build Integration:**

- Configure Miri runner in .cargo/config.toml
- Integrate Kani/Prusti verification in build.rs
- Enable sanitizers for test builds
- Fail CI on Miri errors

**Documentation Validation:**

- Require `# Safety Proof` section for complex unsafe code
- Check that verification references point to actual tests
- Validate proof structure completeness

## Benefits

Rigorous soundness verification provides:

1. **Confidence:** Multiple verification layers catch subtle bugs
2. **Regression Prevention:** Miri tests prevent UB reintroduction
3. **Documentation:** Safety proofs serve as maintenance guides
4. **Correctness:** Formal verification provides mathematical certainty
5. **Security:** Early UB detection prevents exploits

## Examples

### ✅ CORRECT: Complete Miri test coverage

```rust
/// Reads from a buffer with bounds checking.
///
/// # Safety
///
/// Caller must ensure:
/// - `ptr` is valid and aligned
/// - `offset < len`
///
/// # Safety Proof
///
/// Verification:
/// - Miri test: `test_read_buffer_miri`
/// - Property test: `test_read_buffer_proptest`
pub unsafe fn read_buffer(ptr: *const u8, offset: usize, len: usize) -> u8 {
    debug_assert!(!ptr.is_null());
    debug_assert!(offset < len);

    *ptr.add(offset)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_read_buffer_miri() {
        let buffer = vec![1, 2, 3, 4, 5];
        let ptr = buffer.as_ptr();

        unsafe {
            assert_eq!(read_buffer(ptr, 0, 5), 1);
            assert_eq!(read_buffer(ptr, 4, 5), 5);
        }
    }

    // Run with: cargo +nightly miri test
}

#[cfg(test)]
#[cfg(not(miri))] // Proptest doesn't work under Miri
mod proptests {
    use super::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_read_buffer_proptest(
            offset in 0usize..100,
            len in 1usize..100,
        ) {
            let buffer = vec![42u8; len];
            let ptr = buffer.as_ptr();

            if offset < len {
                unsafe {
                    let value = read_buffer(ptr, offset, len);
                    prop_assert_eq!(value, 42);
                }
            }
        }
    }
}
```

### ✅ CORRECT: Formal verification with Kani

```rust
/// Swaps two values through raw pointers.
///
/// # Safety
///
/// - Pointers must be valid and properly aligned
/// - Pointers must not alias unless they point to the same location
///
/// # Safety Proof
///
/// Verification:
/// - Kani proof: `verify_swap_no_ub`
/// - Manual review: Addresses do not alias check
pub unsafe fn swap_raw<T>(a: *mut T, b: *mut T) {
    if a == b {
        return;
    }

    let tmp = std::ptr::read(a);
    std::ptr::copy(b, a, 1);
    std::ptr::write(b, tmp);
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_swap_no_ub() {
        let mut x: u32 = kani::any();
        let mut y: u32 = kani::any();

        let old_x = x;
        let old_y = y;

        unsafe {
            swap_raw(&mut x as *mut u32, &mut y as *mut u32);
        }

        // Verify values swapped correctly
        kani::assert(x == old_y, "x should equal old y");
        kani::assert(y == old_x, "y should equal old x");
    }

    #[kani::proof]
    fn verify_swap_same_pointer() {
        let mut x: u32 = kani::any();
        let old_x = x;

        unsafe {
            swap_raw(&mut x as *mut u32, &mut x as *mut u32);
        }

        // Verify no-op when pointers are the same
        kani::assert(x == old_x, "x unchanged when swapping with itself");
    }
}
```

### ✅ CORRECT: Thread safety verification

```rust
use std::sync::atomic::{AtomicU64, Ordering};

/// Thread-safe counter with verified operations.
///
/// # Safety Proof
///
/// Thread Safety:
/// - All mutations use atomic operations with SeqCst ordering
/// - No data races possible (verified by ThreadSanitizer)
///
/// Verification:
/// - Miri test: `test_concurrent_access`
/// - ThreadSanitizer: Passed on 2025-01-30
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

    pub fn get(&self) -> u64 {
        self.count.load(Ordering::SeqCst)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;
    use std::thread;

    #[test]
    fn test_concurrent_access() {
        let counter = Arc::new(AtomicCounter::new());
        let mut handles = vec![];

        // Spawn 10 threads, each incrementing 1000 times
        for _ in 0..10 {
            let counter_clone = Arc::clone(&counter);
            handles.push(thread::spawn(move || {
                for _ in 0..1000 {
                    counter_clone.increment();
                }
            }));
        }

        for handle in handles {
            handle.join().unwrap();
        }

        // Verify no increments were lost to data races
        assert_eq!(counter.get(), 10_000);
    }
}

// Run with ThreadSanitizer:
// RUSTFLAGS="-Zsanitizer=thread" cargo +nightly test --target x86_64-unknown-linux-gnu
```

### ❌ INCORRECT: Unsafe code without verification

```rust
// Bad: No Miri tests
pub unsafe fn unverified_operation(ptr: *mut u8, offset: usize) {
    *ptr.add(offset) = 42; // Could be UB, no tests verify safety
}

// Bad: No safety proof documentation
pub unsafe fn mystery_function(data: &mut [u8]) {
    // Complex unsafe logic with no explanation or verification
    let ptr = data.as_mut_ptr();
    std::ptr::swap(ptr, ptr.add(1));
}
```

### ❌ INCORRECT: Missing edge case testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_buffer_read() {
        let buffer = vec![1, 2, 3];
        // Bad: Only tests happy path, no edge cases
        unsafe {
            assert_eq!(read_buffer(buffer.as_ptr(), 0, 3), 1);
        }
        // Missing: null pointer, misalignment, bounds violation, zero-sized types
    }
}
```

## Related Rules

- `rust-unsafe-patterns.md` - Unsafe code that requires verification
- `rust-safety-guarantees.md` - Safety contracts to be verified
- `rust-ffi-integration.md` - FFI code requiring Miri testing
