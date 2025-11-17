---
description: "Enforce advanced FFI patterns including C interop, extern declarations, bindgen, and cbindgen best practices"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - ./rust-unsafe-patterns.md
  - ./rust-safety-guarantees.md
  - ./rust-soundness-verification.md
deprecated: false
globs: ["**/*.rs", "**/build.rs", "**/*.toml"]
alwaysApply: true
---

## Cohesion Principle

**Why these aspects belong together:** FFI integration (C interop, extern declarations, and binding generators) forms the complete FFI workflow in Rust. These aspects share the common goal of safely crossing the Rust/C boundary. Manual `extern` declarations define the contract, `#[repr(C)]` ensures memory layout compatibility, bindgen generates Rust bindings from C headers, and cbindgen generates C headers from Rust. Together they form a bidirectional bridge between Rust's safety and C's ubiquity—the complete FFI lifecycle from design to generation to validation.

## Description

This rule enforces comprehensive FFI integration practices including proper C ABI declarations, memory-safe extern function bindings, automated binding generation with bindgen/cbindgen, and cross-language contract validation.

**Scope:**

- C FFI function declarations and calling conventions
- `#[repr(C)]` type layout and ABI compatibility
- bindgen integration (C → Rust binding generation)
- cbindgen integration (Rust → C header generation)
- Cross-language error handling patterns
- Memory ownership across FFI boundaries

**Key Principle:** FFI boundaries are trust boundaries. Every value crossing the boundary must be validated, every memory layout must be verified, and every contract must be explicitly documented.

## Rule

### 1. Extern Declaration Best Practices

**Function Declaration:**

- Use `extern "C"` for C ABI functions
- Add `#[no_mangle]` for functions callable from C
- Document platform-specific calling conventions (e.g., `extern "system"` on Windows)
- Declare functions as `unsafe` unless fully validated internally

**Type Safety:**

- Use `std::os::raw::c_*` types for C primitive types
- Never pass Rust-specific types (String, Vec, Box) directly
- Convert to/from C-compatible representations at boundary

**Error Handling:**

- Return error codes or sentinel values (not Result)
- Document error code meanings in comments
- Use out-parameters for returning complex data

### 2. Memory Layout Compatibility

**`#[repr(C)]` Requirements:**

- Use `#[repr(C)]` for all structs passed to C
- Use `#[repr(transparent)]` for single-field wrappers
- Validate struct size with compile-time assertions
- Document alignment requirements

**Layout Validation:**

```rust
#[repr(C)]
pub struct CStruct { /* ... */ }

const _: () = {
    assert!(std::mem::size_of::<CStruct>() == EXPECTED_SIZE);
    assert!(std::mem::align_of::<CStruct>() == EXPECTED_ALIGN);
};
```

**Enum Representation:**

- Use `#[repr(C)]` or `#[repr(i32)]` for enums passed to C
- Document discriminant values
- Verify exhaustiveness when converting from C integers

### 3. bindgen Integration

**Bindgen Configuration (build.rs):**

```rust
bindgen::Builder::default()
    .header("wrapper.h")
    .parse_callbacks(Box::new(bindgen::CargoCallbacks))
    .allowlist_function("api_.*")
    .allowlist_type("API.*")
    .generate()
    .expect("Failed to generate bindings")
    .write_to_file(out_path.join("bindings.rs"))
```

**Best Practices:**

- Whitelist only needed functions/types with `allowlist_*`
- Use `blocklist_*` to exclude problematic definitions
- Enable `derive_default()` for C structs when safe
- Add `layout_tests()` to verify struct sizes
- Use `impl_debug()` for better ergonomics

**Safety Wrappers:**

- Wrap generated bindings in safe Rust APIs
- Validate all pointer arguments before passing to C
- Convert C error codes to `Result<T, E>`

### 4. cbindgen Integration

**Cbindgen Configuration (cbindgen.toml):**

```toml
language = "C"
include_guard = "MY_LIB_H"
pragma_once = true
documentation = true

[export]
prefix = "MyLib_"
include = ["MyType", "my_function"]

[enum]
rename_variants = "ScreamingSnakeCase"
```

**Best Practices:**

- Add `#[no_mangle]` and `extern "C"` to exported functions
- Use consistent prefix for C function names
- Document all exported functions with `///` comments
- Generate headers in build.rs for consistency

**Header Generation:**

```rust
// build.rs
cbindgen::generate(env!("CARGO_MANIFEST_DIR"))
    .expect("Failed to generate bindings")
    .write_to_file("target/include/mylib.h");
```

### 5. Cross-Language Contract Validation

**Ownership Semantics:**

- Document ownership transfer with `/// Takes ownership` or `/// Borrows`
- Use `Box::into_raw()` / `Box::from_raw()` for ownership transfer
- Never transfer ownership of borrowed references

**Lifetime Management:**

- Use opaque pointers for complex Rust types
- Provide explicit `_destroy` functions for cleanup
- Document lifetime requirements in comments

**Thread Safety:**

- Document thread-safety guarantees for FFI functions
- Use `Send` marker for types passing between threads
- Avoid global mutable state unless synchronized

### 6. FFI and Unwinding

**Be mindful of panics across FFI boundaries.** By default, if a panic occurs in Rust code called from C, it will unwind the stack, which is undefined behavior in C.

- **Use `catch_unwind`**: Wrap the Rust code called from C in `std::panic::catch_unwind` to catch any panics and convert them into an error code.
- **Use `-unwind` ABIs**: For cases where unwinding must cross the FFI boundary (e.g., when interfacing with C++ code that uses exceptions), use an ABI with the `-unwind` suffix, like `"C-unwind"`. This is an advanced feature and should be used with caution.

```rust
use std::panic;

#[no_mangle]
pub extern "C" fn my_rust_api() -> i32 {
    let result = panic::catch_unwind(|| {
        // Rust code that might panic
    });

    match result {
        Ok(_) => 0, // Success
        Err(_) => -1, // Error
    }
}
```

## Implementation

Cursor IDE should enforce these practices through:

**Static Analysis:**

- Detect extern functions without proper type conversions
- Flag Rust-specific types crossing FFI boundaries
- Warn on missing `#[repr(C)]` for FFI structs
- Identify unsafe FFI without validation

**Build Integration:**

- Validate bindgen/cbindgen in build.rs
- Check generated headers for consistency
- Run layout tests on CI

**Linting (clippy):**

- `clippy::missing_safety_doc` for unsafe FFI functions
- `clippy::not_unsafe_ptr_arg_deref` for pointer validation
- Custom lint: Detect Rust types in extern signatures

## Benefits

Proper FFI integration provides:

1. **Interoperability:** Seamless integration with C libraries and systems code
2. **Safety:** Validation at boundaries prevents undefined behavior
3. **Maintainability:** Generated bindings stay synchronized with headers
4. **Performance:** Zero-cost abstractions for cross-language calls
5. **Portability:** Consistent ABI across platforms

## Examples

### ✅ CORRECT: Complete FFI function with validation

```rust
use std::os::raw::{c_char, c_int};
use std::ffi::CStr;

/// Processes a C string and returns status code.
///
/// # Safety
///
/// - `input` must be a valid, null-terminated C string
/// - `input` must remain valid for the duration of this call
/// - Returns 0 on success, -1 on error
#[no_mangle]
pub unsafe extern "C" fn process_string(input: *const c_char) -> c_int {
    // Validate pointer
    if input.is_null() {
        return -1;
    }

    // Safety: We validated pointer is non-null
    let c_str = CStr::from_ptr(input);

    // Convert to Rust string (validates UTF-8)
    let rust_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return -1, // Invalid UTF-8
    };

    // Process with safe Rust code
    internal_process(rust_str);

    0 // Success
}

fn internal_process(s: &str) {
    // Safe Rust logic
}
```

### ✅ CORRECT: FFI struct with layout validation

```rust
/// C-compatible point structure.
///
/// Memory Layout: [x: 8 bytes][y: 8 bytes] = 16 bytes total
/// Alignment: 8 bytes
#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

// Compile-time layout validation
const _: () = {
    const EXPECTED_SIZE: usize = 16;
    const EXPECTED_ALIGN: usize = 8;

    assert!(std::mem::size_of::<Point>() == EXPECTED_SIZE,
            "Point size mismatch");
    assert!(std::mem::align_of::<Point>() == EXPECTED_ALIGN,
            "Point alignment mismatch");
};
```

### ✅ CORRECT: bindgen with safe wrapper

```rust
// Generated by bindgen (bindings.rs)
mod bindings {
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

/// Safe wrapper around C library handle.
pub struct CLibHandle {
    handle: *mut bindings::CHandle,
}

impl CLibHandle {
    /// Creates new handle from C library.
    pub fn new() -> Result<Self, String> {
        let handle = unsafe { bindings::create_handle() };

        if handle.is_null() {
            return Err("Failed to create C handle".into());
        }

        Ok(Self { handle })
    }

    /// Performs operation on handle.
    pub fn operate(&mut self, value: i32) -> Result<i32, String> {
        let result = unsafe {
            bindings::perform_operation(self.handle, value)
        };

        if result < 0 {
            Err(format!("Operation failed with code {}", result))
        } else {
            Ok(result)
        }
    }
}

impl Drop for CLibHandle {
    fn drop(&mut self) {
        unsafe {
            bindings::destroy_handle(self.handle);
        }
    }
}
```

### ✅ CORRECT: cbindgen exported API

```rust
/// Context handle for C clients.
///
/// Opaque type - do not access fields directly.
#[repr(C)]
pub struct MyContext {
    _private: [u8; 0],
}

/// Creates a new context.
///
/// Returns NULL on failure.
/// Call `mylib_context_destroy` to free.
#[no_mangle]
pub extern "C" fn mylib_context_create() -> *mut MyContext {
    let ctx = Box::new(ContextImpl::new());
    Box::into_raw(ctx) as *mut MyContext
}

/// Destroys a context.
///
/// # Safety
///
/// - `ctx` must be a valid pointer returned from `mylib_context_create`
/// - `ctx` must not be used after this call
/// - `ctx` must not be NULL
#[no_mangle]
pub unsafe extern "C" fn mylib_context_destroy(ctx: *mut MyContext) {
    if ctx.is_null() {
        return;
    }

    // Safety: Caller guarantees ctx came from mylib_context_create
    let _ = Box::from_raw(ctx as *mut ContextImpl);
}

struct ContextImpl {
    // Internal Rust implementation
}

impl ContextImpl {
    fn new() -> Self {
        Self {}
    }
}
```

### ❌ INCORRECT: Unsafe FFI without validation

```rust
// Bad: No pointer validation
#[no_mangle]
pub unsafe extern "C" fn bad_function(ptr: *const u8) -> u8 {
    *ptr // Dereference without null check or bounds validation
}

// Bad: Passing Rust types across FFI
#[no_mangle]
pub extern "C" fn bad_ffi_types(s: String) -> Vec<u8> {
    // String and Vec are NOT C-compatible!
    s.into_bytes()
}
```

### ❌ INCORRECT: Missing #[repr(C)]

```rust
// Bad: No #[repr(C)] for FFI struct
pub struct BadStruct {
    x: u32,
    y: u64, // Undefined layout!
}

extern "C" {
    fn c_function(s: BadStruct); // Undefined behavior!
}
```

### ❌ INCORRECT: No error handling

```rust
// Bad: No error reporting mechanism
#[no_mangle]
pub unsafe extern "C" fn risky_operation(input: *const u8) {
    // What if this panics? C code can't handle it!
    let data = std::slice::from_raw_parts(input, 100);
    process(data); // Might panic!
}
```

## Related Rules

- `rust-unsafe-patterns.md` - Foundation for unsafe FFI operations
- `rust-safety-guarantees.md` - Safety contracts across FFI boundaries
- `rust-soundness-verification.md` - Testing FFI code for correctness

## References

- [The Rustonomicon: Foreign Function Interface (FFI)](https://doc.rust-lang.org/nomicon/ffi.html)
- [The `libc` crate](https://crates.io/crates/libc)
- [The `bindgen` User Guide](https://rust-lang.github.io/rust-bindgen/)
- [The `cbindgen` User Guide](https://github.com/mozilla/cbindgen/blob/master/docs/user-guide.md)
