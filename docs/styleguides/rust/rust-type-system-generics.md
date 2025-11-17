---
title: "Rust Type System and Generics Best Practices"
description: "Enforce best practices for using Rust's type system, including generics, traits, and lifetimes, to create flexible and type-safe abstractions."
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-ownership-borrowing.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Type System and Generics Best Practices

## Cohesion Principle

**Why These Aspects Belong Together:**

Rust's power to create zero-cost abstractions comes from the cohesive interplay of its type system components:

1. **Generics**: Allow code to be written abstractly over different types, reducing duplication.
2. **Traits**: Define shared behavior that generic types can be constrained to, ensuring type safety.
3. **Lifetimes**: A form of generics that ensures that all references are valid, a cornerstone of Rust's memory safety.

These concepts are interdependent. Generics are not useful without traits to constrain them, and both are subject to the lifetime rules enforced by the borrow checker. Together, they enable the creation of highly flexible, yet type-safe and performant, APIs.

## Description

This rule enforces best practices for using Rust's type system, with a focus on generics, traits, and trait bounds. Correctly using these features is key to writing idiomatic, reusable, and maintainable Rust code that is both abstract and efficient.

## Rule

### 1. Use Generics to Reduce Code Duplication

**MANDATORY**: Use generic functions, structs, and enums to operate on abstract types, avoiding the need to write separate implementations for each concrete type.

```rust
// ✅ GOOD: A generic function that works on any type that supports partial ordering.
fn largest<T: PartialOrd>(list: &[T]) -> &T {
    let mut largest = &list[0];
    for item in list {
        if item > largest {
            largest = item;
        }
    }
    largest
}

// ✅ GOOD: A generic struct that can hold any type.
struct Point<T> {
    x: T,
    y: T,
}
```

### 2. Use Trait Bounds to Constrain Generic Types

**MANDATORY**: Use trait bounds to specify the behavior that a generic type must implement. For complex bounds, use a `where` clause for readability.

```rust
use std::fmt::{Debug, Display};

// Simple trait bound
fn print_item<T: Display>(item: T) {
    println!("{}", item);
}

// ✅ GOOD: `where` clause for multiple, complex bounds
fn process_items<T, U>(item1: T, item2: U)
where
    T: Display + Clone,
    U: Debug + Send,
{
    // ...
}

// ❌ BAD: Hard to read without a `where` clause
fn bad_process_items<T: Display + Clone, U: Debug + Send>(item1: T, item2: U) {
    // ...
}
```

### 3. Use Associated Types to Define a Family of Types

**MANDATORY**: In a trait, use associated types when a trait needs an inner type that is related to the trait itself. This is often more ergonomic than using a generic type parameter on the trait.

The classic example is the `Iterator` trait:

```rust
pub trait Iterator {
    // `Item` is an associated type. Each implementation of `Iterator`
    // will specify the concrete type of `Item`.
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}
```

### 4. Understand Common Standard Library Traits

**MANDATORY**: Be familiar with and correctly use common traits from the standard library.

- **`Sized`**: A marker trait indicating that a type has a known size at compile time. Most types are `Sized`. Use `?Sized` to opt-out, allowing for dynamically sized types (DSTs) like `&str` and `&[T]`.
- **`Clone` vs. `Copy`**:
  - `Copy`: For types that can be duplicated with a simple bit-for-bit copy. The original value is still usable after assignment.
  - `Clone`: For types that need a more complex duplication process (e.g., allocating memory). `clone()` is an explicit method call.
- **`Send` and `Sync`**: Marker traits for thread safety.
  - `Send`: A type is `Send` if it can be safely transferred to another thread.
  - `Sync`: A type is `Sync` if it can be safely shared between threads (i.e., `&T` is `Send`).

### 5. Use `const` Generics for Compile-Time Values

**MANDATORY**: Use `const` generics when you need to abstract over constant values, such as array sizes. This allows for type-safe operations with sizes known at compile time.

```rust
// ✅ GOOD: A function that works on an array of any size.
fn process_array<const N: usize>(arr: [i32; N]) {
    println!("Array size: {}", N);
}

fn main() {
    process_array([1, 2, 3]);       // N is 3
    process_array([1, 2, 3, 4, 5]); // N is 5
}
```

## Implementation

- **Compiler Errors**: The Rust compiler is the primary enforcer of rules related to generics, traits, and lifetimes.
- **Clippy Lints**:
  - `clippy::type_complexity`: Warns about types that are becoming too complex, suggesting type aliases.
  - `clippy::trivially_copy_pass_by_ref`: Suggests passing `Copy` types by value instead of by reference.

## Benefits

- **Zero-Cost Abstractions**: Generics in Rust are monomorphized at compile time, meaning there is no runtime performance penalty for using them.
- **Type Safety**: Trait bounds ensure that generic functions can only be called with types that support the required behavior.
- **Code Reusability**: Write a function or data structure once and use it for many different types.

## References

- [The Rust Book: Generic Data Types](https://doc.rust-lang.org/book/ch10-01-syntax.html)
- [The Rust Book: Traits](https://doc.rust-lang.org/book/ch10-02-traits.html)
- [The Rust Book: Lifetimes](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html)
