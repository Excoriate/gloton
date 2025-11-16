---
description: "Enforce best practices for documentation in Rust code including public API documentation, code examples, and module documentation"
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-testing.md"
  - "./rust-safety-guarantees.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Documentation Best Practices

## Cohesion Principle

**Why These Aspects Belong Together:**

Effective Rust documentation is a cohesive system where different levels of documentation work together to provide a complete picture of a crate's functionality. This includes:

1.  **Crate and Module-Level Documentation**: High-level overviews that explain the purpose and scope of the crate or module.
2.  **Item-Level Documentation**: Detailed explanations for public functions, structs, enums, and traits.
3.  **Code Examples**: Demonstrations of how to use the API, which also double as tests.
4.  **Safety, Error, and Panic Contracts**: Clear communication of the conditions under which code may be unsafe, return an error, or panic.

These elements are interdependent. Crate-level documentation provides context for the modules, module documentation explains how items fit together, and item-level documentation, with its examples and safety notes, clarifies the specifics. `rustdoc` is the unifying tool that processes these components into a single, navigable HTML output.

## Description

This rule enforces best practices for writing documentation in Rust code. High-quality documentation is essential for creating usable, maintainable, and trustworthy libraries and applications. It covers everything from high-level crate descriptions to detailed explanations of function arguments, return values, errors, and safety invariants.

## Rule

### 1. Document Every Public Item

**MANDATORY**: Every public item (`mod`, `struct`, `enum`, `fn`, `trait`, `macro`) must have documentation. Private items should be commented where their logic is complex or non-obvious.

- Use `///` for item-level documentation.
- Use `//!` for module or crate-level documentation (placed at the beginning of the file).

### 2. Start with Crate-Level Documentation

**MANDATORY**: Every library crate must have crate-level documentation in `src/lib.rs`. This is the front page of your documentation.

```rust
//! # My Awesome Crate
//!
//! `my_awesome_crate` is a library for doing awesome things.
//! It provides functionality for...
//!
//! ## Examples
//!
//! ```
//! use my_awesome_crate::do_something_awesome;
//!
//! # fn main() -> Result<(), Box<dyn std::error::Error>> {
//! do_something_awesome("world")?;
//! # Ok(())
//! # }
//! ```

// ... rest of lib.rs
```

### 3. Write Clear and Concise Summaries

**MANDATORY**: The first line of a doc comment should be a short, concise summary of the item's purpose. Follow it with a blank line and then more detailed explanations if necessary.

```rust
/// Calculates the factorial of a non-negative integer.
///
/// This function uses a recursive approach to calculate the factorial.
/// It is not optimized for very large numbers and may overflow.
pub fn factorial(n: u64) -> u64 {
    // ...
}
```

### 4. Provide Runnable Code Examples

**MANDATORY**: Include runnable code examples in your documentation to demonstrate usage. `rustdoc` will test these examples with `cargo test`.

- Use ````rust` blocks for examples.
- Hide setup code that is not relevant to the example with `#`.
- Use `#[should_panic]` for examples that are expected to panic.
- Use `compile_fail` for examples that should not compile.

```rust
/// # Examples
///
/// ```
/// use my_crate::add;
///
/// assert_eq!(add(2, 3), 5);
/// ```
```

### 5. Document Panics, Errors, and Safety

**MANDATORY**: Clearly document the conditions under which a function may panic, return an error, or requires `unsafe` context.

- **`# Panics`**: Explain what will cause the function to panic.
- **`# Errors`**: Describe the conditions that will lead to an `Err` variant being returned.
- **`# Safety`**: For `unsafe` functions, specify the invariants that the caller must uphold for the function to be safe to call.

```rust
/// # Panics
///
/// This function will panic if `divisor` is zero.
///
/// # Errors
///
/// Returns `Err` if the input string cannot be parsed as a number.
///
/// # Safety
///
/// The pointer `ptr` must be valid for reads of `len` bytes.
```

### 6. Use Intra-Doc Links

**MANDATORY**: Use intra-doc links to connect related items, improving navigability.

```rust
/// A `struct` that works with [`MyEnum`].
///
/// See also [`my_function()`].
pub struct MyStruct;

pub enum MyEnum {}

pub fn my_function() {}
```

## Implementation

- **`cargo doc`**: The primary tool for generating documentation. Use `cargo doc --open` to build and view the docs locally.
- **Clippy Lints**:
  - `clippy::missing_docs_in_private_items`: Can be enabled to enforce documentation on private items as well.
  - `clippy::missing_errors_doc`: Warns if a function returns a `Result` but lacks an `# Errors` section.
  - `clippy::missing_panics_doc`: Warns if a function can panic but lacks a `# Panics` section.

## Benefits

- **Usability**: Good documentation makes a library easier to learn and use.
- **Maintainability**: Clear explanations and examples make the code easier to understand and modify.
- **Correctness**: Writing documentation forces you to think through edge cases and contracts, and tested examples ensure correctness.
- **Trust**: Well-documented code appears more professional and trustworthy to users.

## Examples

### ✅ CORRECT: Well-Documented Function

```rust
use std::num::ParseIntError;

/// Parses a string into a `u32`.
///
/// This function is a simple wrapper around `str::parse`.
///
/// # Arguments
///
/// * `s` - A string slice to parse.
///
/// # Examples
///
/// ```
/// use my_crate::parse_number;
///
/// assert_eq!(parse_number("42").unwrap(), 42);
/// ```
///
/// # Errors
///
/// Returns a [`ParseIntError`] if the string does not represent a valid `u32`.
pub fn parse_number(s: &str) -> Result<u32, ParseIntError> {
    s.parse()
}
```

### ❌ INCORRECT: Poorly Documented Function

```rust
// ❌ Missing summary, examples, and error documentation.
pub fn do_stuff(s: &str) -> Result<u32, ParseIntError> {
    s.parse()
}
```

## References

- [The Rust Book: Publishing to Crates.io](https://doc.rust-lang.org/book/ch14-02-publishing-to-crates-io.html)
- [The `rustdoc` Book](https://doc.rust-lang.org/rustdoc/index.html)
- [Rust API Guidelines: Documentation](https://rust-lang.github.io/api-guidelines/documentation.html)