---
title: "Rust Ownership, Borrowing, and Lifetimes Best Practices"
description: "Enforce best practices for Rust's ownership, borrowing, and lifetime system to ensure memory safety and prevent common errors."
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

# Rust Ownership, Borrowing, and Lifetimes Best Practices

## Cohesion Principle

**Why These Aspects Belong Together:**

Rust's memory safety guarantees are built upon three interconnected concepts that work as a unified system:

1. **Ownership**: Every value has a single owner. When the owner goes out of scope, the value is dropped. This ensures resources are cleaned up automatically.
2. **Borrowing**: You can borrow access to a value without taking ownership. The borrow checker enforces rules to prevent data races and dangling pointers.
3. **Lifetimes**: Lifetimes are the scope for which a reference is valid. They are a key part of the borrow checker's analysis, ensuring that references do not outlive the data they point to.

These concepts are inseparable. Ownership dictates when a value is dropped, borrowing allows for flexible access to data without transferring ownership, and lifetimes ensure that all borrows are valid. Understanding them as a single system is fundamental to writing safe and efficient Rust code.

## Description

This rule enforces best practices for using Rust's ownership, borrowing, and lifetime system. Correctly applying these principles is essential for writing idiomatic, safe, and performant Rust code, preventing common errors like use-after-free, data races, and null pointer dereferences at compile time.

## Rule

### 1. Prefer Borrowing Over Moving Ownership

**MANDATORY**: When passing data to a function, prefer borrowing (`&` or `&mut`) over moving ownership, unless the function logically needs to consume the value.

- **Borrowing (`&T`)**: Allows a function to read data without taking ownership.
- **Mutable Borrowing (`&mut T`)**: Allows a function to modify data without taking ownership.
- **Moving (`T`)**: Transfers ownership to the function. The original variable can no longer be used.

```rust
struct Item;

// ✅ GOOD: Borrows the item, caller retains ownership.
fn process_item(item: &Item) {
    // ...
}

// ❌ BAD: Takes ownership, forcing the caller to clone or give up the item.
fn process_item_owned(item: Item) {
    // ...
}

fn main() {
    let item = Item;
    process_item(&item);
    process_item(&item); // Can still use `item`

    // process_item_owned(item);
    // process_item_owned(item); // Compile error: use of moved value
}
```

### 2. Adhere to the Borrowing Rules

**MANDATORY**: At any given time, you can have either one mutable reference OR any number of immutable references, but not both.

This rule is enforced by the compiler and is a cornerstone of Rust's data race prevention.

```rust
fn main() {
    let mut data = vec![1, 2, 3];

    // ✅ CORRECT: Multiple immutable references are allowed.
    let r1 = &data;
    let r2 = &data;
    println!("{:?}, {:?}", r1, r2);

    // ✅ CORRECT: A single mutable reference is allowed.
    let m1 = &mut data;
    m1.push(4);
    println!("{:?}", m1);

    // ❌ INCORRECT: Cannot have a mutable reference while immutable ones exist.
    // let r3 = &data;
    // let m2 = &mut data; // Compile error
    // println!("{:?}, {:?}", r3, m2);
}
```

### 3. Understand and Use Lifetimes When Needed

**MANDATORY**: While the compiler can infer lifetimes in many cases (lifetime elision), you must provide explicit lifetime annotations when the compiler cannot determine the validity of a reference on its own.

- Use descriptive lifetime names, like `'a`, `'b`, or `'static`.
- `'static` is a special lifetime that indicates a reference can live for the entire duration of the program.

```rust
// ✅ CORRECT: Explicit lifetime 'a ensures the returned reference is valid
// as long as both input references are valid.
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

// ❌ INCORRECT: The compiler doesn't know which lifetime to use for the return.
// fn longest_broken(x: &str, y: &str) -> &str { ... } // Compile error
```

### 4. Use Slices for Flexible Views into Collections

**MANDATORY**: Use slices (`&[T]` or `&str`) for functions that operate on contiguous sequences of data. This makes your functions more flexible, as they can accept a variety of collection types.

```rust
// ✅ GOOD: Accepts any string slice.
fn print_slice(s: &str) {
    println!("{}", s);
}

fn main() {
    let s1 = String::from("hello");
    let s2 = "world";

    print_slice(&s1);       // Works with String
    print_slice(&s1[..2]);  // Works with a slice of a String
    print_slice(s2);        // Works with a string literal
}
```

### 5. Use Smart Pointers for Advanced Ownership Scenarios

**MANDATORY**: Use the appropriate smart pointer for your ownership needs.

- **`Box<T>`**: For allocating a value on the heap and transferring ownership.
- **`Rc<T>`**: For multiple *owners* of the same data within a single thread (Reference Counting).
- **`Arc<T>`**: For multiple *owners* of the same data across multiple threads (Atomic Reference Counting).
- **`RefCell<T>`**: For enforcing borrowing rules at runtime instead of compile time (interior mutability). Often used with `Rc<T>`.

```rust
use std::rc::Rc;
use std::sync::Arc;
use std::cell::RefCell;

// Rc for single-threaded shared ownership
let a = Rc::new(5);
let b = Rc::clone(&a); // `b` is another owner

// Arc for multi-threaded shared ownership
let x = Arc::new(10);
let y = Arc::clone(&x);
std::thread::spawn(move || {
    println!("{}", y);
});

// RefCell for interior mutability
let data = RefCell::new(vec![1, 2, 3]);
let mut mut_ref = data.borrow_mut();
mut_ref.push(4);
```

## Implementation

- **Clippy Lints**:
  - `clippy::needless_clone`: Warns about unnecessary clones.
  - `clippy::mut_mut`: Warns about creating a mutable reference from another mutable reference.
  - `clippy::needless_lifetimes`: Warns when explicit lifetimes are not needed due to elision.
- **Compiler Errors**: The Rust compiler (`rustc`) is the primary enforcer of ownership and borrowing rules.

## Benefits

- **Memory Safety**: Eliminates entire classes of bugs like dangling pointers, use-after-free, and data races at compile time.
- **Performance**: No runtime overhead from a garbage collector. Resource management is deterministic.
- **Concurrency**: The ownership system makes it much safer to write concurrent code.

## References

- [The Rust Book: Understanding Ownership](https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html)
- [The Rust Book: Smart Pointers](https://doc.rust-lang.org/book/ch15-00-smart-pointers.html)
- [Rustonomicon: Lifetimes](https://doc.rust-lang.org/nomicon/lifetimes.html)
