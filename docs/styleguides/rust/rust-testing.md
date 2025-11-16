---
title: "Rust Testing Best Practices"
description: "Enforce best practices for testing in Rust, including test organization, writing effective tests, and controlling test execution."
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-documentation.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Testing Best Practices

## Cohesion Principle

**Why These Aspects Belong Together:**

A robust testing strategy in Rust relies on a cohesive combination of different test types and organizational patterns:

1.  **Unit Tests**: Small, focused tests that verify the functionality of individual components, often including private implementation details.
2.  **Integration Tests**: Larger tests that exercise the public API of a crate, ensuring that different parts of the library work together correctly.
3.  **Documentation Tests**: Examples in the documentation that are compiled and run as tests, ensuring that the documentation is always up-to-date and correct.

These test types are complementary. Unit tests provide granular feedback, integration tests ensure the public API is sound, and doc tests guarantee that the examples users will see are correct. `cargo test` is the unifying tool that runs all of these tests together, providing a comprehensive view of the crate's correctness.

## Description

This rule enforces best practices for writing automated tests in Rust. A strong test suite is essential for building reliable and maintainable software. This guide covers how to organize tests, write effective assertions, control test execution, and leverage Rust's different test types.

## Rule

### 1. Test Organization

**MANDATORY**: Organize your tests into unit and integration tests according to Rust's conventions.

-   **Unit Tests**: Place unit tests in a `tests` module inside the same file as the code they are testing, annotated with `#[cfg(test)]`. This allows them to access private functions and structs.

    ```rust
    // src/my_module.rs
    fn private_function() -> bool {
        true
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn test_private_function() {
            assert!(private_function());
        }
    }
    ```

-   **Integration Tests**: Place integration tests in a `tests` directory at the root of your crate. Each file in this directory is compiled as a separate crate and can only test the public API of your library.

    ```
    // tests/integration_test.rs
    use my_crate::public_function;

    #[test]
    fn test_public_api() {
        assert_eq!(public_function(), 42);
    }
    ```

### 2. Writing Good Tests

**MANDATORY**: Write clear, focused tests that follow the Arrange-Act-Assert pattern and use the appropriate assertion macros.

-   **AAA Pattern**:
    1.  **Arrange**: Set up any necessary data or state.
    2.  **Act**: Call the function or method you want to test.
    3.  **Assert**: Check that the result is what you expect.

-   **Assertion Macros**:
    -   `assert!(expression)`: Panics if `expression` is `false`.
    -   `assert_eq!(left, right)`: Panics if `left != right`.
    -   `assert_ne!(left, right)`: Panics if `left == right`.

-   **Testing for Panics**: Use `#[should_panic]` to verify that a function panics when it should.

    ```rust
    #[test]
    #[should_panic(expected = "out of bounds")]
    fn test_panic() {
        let v = vec![1];
        v[10]; // This should panic
    }
    ```

-   **Using `Result` in Tests**: Tests can return a `Result<T, E>`, which allows you to use the `?` operator. The test will fail if it returns an `Err`.

    ```rust
    #[test]
    fn test_with_result() -> Result<(), String> {
        if 2 + 2 == 4 {
            Ok(())
        } else {
            Err(String::from("two plus two does not equal four"))
        }
    }
    ```

### 3. Controlling Test Execution

**MANDATORY**: Know how to run specific tests to speed up your development workflow.

-   **Run all tests**: `cargo test`
-   **Run a single test**: `cargo test test_name`
-   **Run tests in a module**: `cargo test module_name::`
-   **Run ignored tests**: `cargo test -- --ignored`
-   **Show output from passing tests**: `cargo test -- --show-output`
-   **Run tests in a single thread**: `cargo test -- --test-threads=1`

### 4. Async Testing

**MANDATORY**: For asynchronous code, use an async test runner like `tokio::test`.

```rust
#[cfg(test)]
mod tests {
    use tokio;

    async fn my_async_function() -> bool {
        true
    }

    #[tokio::test]
    async fn test_async() {
        assert!(my_async_function().await);
    }
}
```

## Implementation

-   **`cargo test`**: The primary tool for running all types of tests.
-   **Clippy Lints**:
    -   `clippy::cognitive_complexity`: Can help identify functions that are too complex and may be difficult to test.
-   **Code Coverage Tools**: Use tools like `cargo-tarpaulin` or `grcov` to measure test coverage.

## Benefits

-   **Correctness**: A comprehensive test suite helps ensure that your code behaves as expected.
-   **Regression Prevention**: Tests catch unintended side effects of code changes.
-   **Confident Refactoring**: A good test suite allows you to refactor your code with confidence.
-   **Executable Documentation**: Tests serve as examples of how to use your API.

## References

-   [The Rust Book: How to Write Tests](https://doc.rust-lang.org/book/ch11-01-writing-tests.html)
-   [The Rust Book: Test Organization](https://doc.rust-lang.org/book/ch11-03-test-organization.html)
-   [Async Testing with Tokio](https://tokio.rs/tokio/tutorial/testing)