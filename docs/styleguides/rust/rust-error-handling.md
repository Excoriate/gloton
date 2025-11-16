---
description: "Enforce best practices for error handling in Rust, including `Result` usage, error propagation, custom error types, and panic handling."
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-safety-guarantees.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Error Handling Best Practices

## Cohesion Principle

**Why These Aspects Belong Together:**

Effective error handling in Rust is a cohesive system that combines several key elements:

1.  **Error Representation**: Using enums like `Result<T, E>` and `Option<T>` to represent the possibility of failure or absence of a value.
2.  **Error Propagation**: The `?` operator provides a standardized, ergonomic way to propagate errors up the call stack.
3.  **Custom Error Types**: Defining custom error types allows for rich, contextual error information, which is crucial for debugging and reliable operation.
4.  **Panic Strategy**: Distinguishing between recoverable errors (which should be handled) and unrecoverable errors (which should cause a panic).

These components are interdependent. `Result` is the foundation for recoverable errors, the `?` operator makes working with `Result` manageable, custom error types make `Result` more informative, and a clear panic strategy defines the boundary between expected failures and catastrophic bugs.

## Description

This rule enforces best practices for error handling in Rust. Robust error handling is a cornerstone of reliable Rust software, ensuring that programs are resilient to failure and easy to debug. This guide covers the use of `Result` and `Option`, the `?` operator for error propagation, the creation of custom error types, and the appropriate use of `panic!`.

## Rule

### 1. Use `Result` for Recoverable Errors, `Option` for Absence

**MANDATORY**: Distinguish between operations that can fail and values that can be absent.

-   **`Result<T, E>`**: Use for operations that can succeed (returning `Ok(T)`) or fail (returning `Err(E)`). This is for *recoverable* errors.
-   **`Option<T>`**: Use when a value could be something (`Some(T)`) or nothing (`None`). This is not for errors, but for managing optionality.

```rust
// ✅ CORRECT: Using Result for a fallible operation
fn parse_number(s: &str) -> Result<i32, std::num::ParseIntError> {
    s.parse()
}

// ✅ CORRECT: Using Option for a value that may not exist
fn find_user(id: u32) -> Option<User> {
    // ... logic to find user ...
}

// ❌ INCORRECT: Using Option to represent a failure case
fn bad_parse(s: &str) -> Option<i32> {
    s.parse().ok() // This discards the error information
}
```

### 2. Propagate Errors with the `?` Operator

**MANDATORY**: Use the `?` operator to propagate errors up the call stack. It simplifies error handling and makes the code more readable.

```rust
use std::fs::File;
use std::io::{self, Read};

// ✅ CORRECT: Using `?` to propagate errors
fn read_username_from_file() -> Result<String, io::Error> {
    let mut username_file = File::open("username.txt")?;
    let mut username = String::new();
    username_file.read_to_string(&mut username)?;
    Ok(username)
}

// ❌ INCORRECT: Manual error handling with `match`
fn verbose_read_username() -> Result<String, io::Error> {
    let username_file = File::open("username.txt");
    let mut username_file = match username_file {
        Ok(file) => file,
        Err(e) => return Err(e),
    };

    let mut username = String::new();
    match username_file.read_to_string(&mut username) {
        Ok(_) => Ok(username),
        Err(e) => Err(e),
    }
}
```

### 3. Create Custom Error Types

**MANDATORY**: For libraries and applications, create custom error types to provide meaningful context. The `thiserror` crate is highly recommended for this.

```rust
use thiserror::Error;
use std::io;

#[derive(Error, Debug)]
pub enum DataError {
    #[error("I/O error: {0}")]
    Io(#[from] io::Error),
    #[error("Parsing error: {0}")]
    Parse(#[from] std::num::ParseIntError),
    #[error("User not found: {0}")]
    UserNotFound(String),
}

fn get_user_age() -> Result<u8, DataError> {
    let username = read_username_from_file()?; // Propagates io::Error, converted by #[from]
    let age_str = fetch_age_for_user(&username)?;
    let age = age_str.parse()?; // Propagates ParseIntError, converted by #[from]
    Ok(age)
}
```

For simple applications, `anyhow` can be a good choice for its ease of use, but custom error types are preferred for libraries.

### 4. Handle Panics Appropriately

**MANDATORY**: `panic!` should be reserved for unrecoverable errors that indicate a bug in the program.

-   **Avoid `unwrap()`**: In production code, `unwrap()` can lead to unexpected panics. Prefer `match` or `if let` to handle `Result` and `Option`.
-   **Use `expect()` in tests and examples**: `expect()` is like `unwrap()` but with a custom message, which is useful for explaining why you expect an operation to succeed.
-   **Document Panics**: If a function has conditions under which it will panic, document them clearly in a `# Panics` section.

```rust
// ✅ CORRECT: Handling a Result properly
let file = File::open("data.txt");
let mut file = match file {
    Ok(f) => f,
    Err(e) => {
        eprintln!("Failed to open file: {}", e);
        return;
    }
};

// ❌ INCORRECT: Using `unwrap()` in production code
let file = File::open("data.txt").unwrap();

// ✅ ACCEPTABLE: Using `expect()` in tests
#[test]
fn test_file_creation() {
    let file = File::create("test.txt").expect("Failed to create test file");
}
```

## Implementation

-   **Clippy Lints**:
    -   `clippy::unwrap_used`: Warns about the use of `unwrap()`.
    -   `clippy::expect_used`: Warns about the use of `expect()`.
    -   `clippy::result_unit_err`: Warns about `Result` with `()` as the error type.
-   **IDE Integration**: IDEs can provide quick fixes to replace `unwrap()` with proper error handling.

## Benefits

-   **Robustness**: Explicitly handling errors makes programs more resilient to failure.
-   **Maintainability**: Clear error types and propagation make the code easier to understand and debug.
-   **Security**: Prevents unexpected panics that could lead to denial-of-service vulnerabilities.
-   **Developer Experience**: The `?` operator and custom error types make error handling in Rust both ergonomic and powerful.

## References

-   [The Rust Book: Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
-   [`thiserror` Crate](https://docs.rs/thiserror/)
-   [`anyhow` Crate](https://docs.rs/anyhow/)
-   [Rust API Guidelines: Error Handling](https://rust-lang.github.io/api-guidelines/error-handling.html)