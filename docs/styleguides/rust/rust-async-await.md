---
description: "Enforce best practices for asynchronous programming in Rust including async function design, future handling, runtime usage, and structured concurrency"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - "./rust-error-handling.md"
  - "./rust-tracing-instrumentation.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Async/Await Best Practices

## Cohesion Principle

**Why These Aspects Belong Together:**

Asynchronous programming in Rust forms a cohesive system where `async fn` syntax, the `Future` trait, `async` runtimes, and structured concurrency patterns work together to enable efficient, non-blocking I/O. `async fn` provides the ergonomic syntax for defining asynchronous operations, which return a `Future`. The `Future` trait defines the contract for values that complete asynchronously. An `async` runtime (like Tokio) is required to execute these futures, poll them to completion, and manage tasks. Structured concurrency patterns (like `tokio::spawn` and `join!`) provide the mechanisms for managing concurrent tasks safely and efficiently. These components are interdependent: `async fn` is useless without a runtime to execute its futures, and structured concurrency is the primary means of managing multiple `async` operations.

## Description

This rule enforces best practices for asynchronous programming in Rust, focusing on the `async/.await` syntax, `Future` handling, runtime usage (Tokio), and structured concurrency patterns. Proper async programming is critical for building scalable, high-performance I/O-bound applications.

## Rule

### 1. Use `async fn` for Asynchronous Operations

**MANDATORY**: Use `async fn` to define functions that perform non-blocking operations. An `async fn` returns a `Future`, which is a value that may not be ready yet.

```rust
// ✅ CORRECT: `async fn` returns a `Future`
pub async fn fetch_data_from_api(url: &str) -> Result<String, reqwest::Error> {
    reqwest::get(url).await?.text().await
}

// ❌ INCORRECT: Blocking function in async context
pub fn fetch_data_blocking(url: &str) -> String {
    // This blocks the current thread, defeating the purpose of async
    std::thread::sleep(std::time::Duration::from_secs(1));
    "data".to_string()
}
```

### 2. Use `.await` to Drive Futures to Completion

**MANDATORY**: Use the `.await` operator inside an `async` function or block to wait for a `Future` to complete. Futures in Rust are lazy; they do nothing until they are `.await`ed.

```rust
async fn main() {
    let future = fetch_data_from_api("https://example.com");
    // `future` does nothing yet...

    let data = future.await; // Now the future is executed
    println!("Data: {:?}", data);
}
```

### 3. Choose and Use an Async Runtime

**MANDATORY**: Rust's standard library does not include an async runtime. You must choose one to execute your futures. **Tokio** is the de-facto standard for production systems.

```rust
// ✅ CORRECT: Use `#[tokio::main]` to start the Tokio runtime
#[tokio::main]
async fn main() {
    println!("Running inside Tokio runtime");
    // Your async code here...
}

// ❌ INCORRECT: Trying to `.await` without a runtime
fn main() {
    let future = async { 42 };
    let value = future.await; // Compile error: `.await` is only allowed inside `async` functions
}
```

### 4. Avoid Blocking in Async Code

**MANDATORY**: Never call blocking functions (standard library I/O, `std::thread::sleep`, CPU-intensive work) directly within an `async` function. This blocks the executor's thread, preventing other tasks from running.

```rust
// ❌ INCORRECT: Blocking in an async task
#[tokio::main]
async fn main() {
    // This blocks the entire thread, no other tasks can run
    std::thread::sleep(std::time::Duration::from_secs(5));
}

// ✅ CORRECT: Use the runtime's non-blocking equivalents
#[tokio::main]
async fn main() {
    // This yields control, allowing other tasks to run
    tokio::time::sleep(std::time::Duration::from_secs(5)).await;
}

// ✅ CORRECT: Offload blocking work to a dedicated thread pool
#[tokio::main]
async fn main() {
    let result = tokio::task::spawn_blocking(|| {
        // CPU-intensive or blocking I/O work
        compute_heavy_stuff()
    }).await.unwrap();
}
```

### 5. Use Structured Concurrency for Managing Tasks

**MANDATORY**: Use structured concurrency primitives like `tokio::spawn`, `tokio::join!`, and `select!` to manage concurrent tasks.

```rust
// ✅ CORRECT: Spawning concurrent tasks
#[tokio::main]
async fn main() {
    let task1 = tokio::spawn(async {
        fetch_data_from_api("https://example.com").await
    });

    let task2 = tokio::spawn(async {
        fetch_data_from_api("https://google.com").await
    });

    // Wait for both tasks to complete
    let result1 = task1.await.unwrap();
    let result2 = task2.await.unwrap();
}

// ✅ CORRECT: Using `join!` to run futures concurrently
#[tokio::main]
async fn main() {
    let (res1, res2) = tokio::join!(
        fetch_data_from_api("https://example.com"),
        fetch_data_from_api("https://google.com")
    );
}
```

### 6. Use Native `async fn` in Traits

**MANDATORY**: As of Rust 1.75, `async fn` can be used directly in traits. This is the standard and preferred way to define asynchronous methods in traits.

```rust
// ✅ CORRECT: Use native `async fn` in a trait
pub trait MessageBus {
    async fn send(&self, message: &str) -> Result<(), anyhow::Error>;
}

struct MyBus;

impl MessageBus for MyBus {
    async fn send(&self, message: &str) -> Result<(), anyhow::Error> {
        println!("Sending message: {}", message);
        // ... async operation ...
        Ok(())
    }
}
```

**NOTE on `dyn Trait`**: Native `async fn` in traits does not yet support `dyn Trait` (trait objects). If you need dynamic dispatch for your async trait, the `async-trait` crate is still a valid workaround.

```rust
// ✅ CORRECT (when `dyn Trait` is needed): Use `async-trait` crate
use async_trait::async_trait;

#[async_trait]
pub trait DynMessageBus {
    async fn send(&self, message: &str) -> Result<(), anyhow::Error>;
}

// This allows you to create a trait object:
// let bus: Box<dyn DynMessageBus> = ...;
```

## Implementation

Cursor IDE and linters should enforce these practices through:
- **Detection of blocking calls**: Flag usage of `std::thread::sleep`, `std::fs`, etc., inside `async` blocks.
- **Runtime validation**: Ensure `#[tokio::main]` or another runtime entry point is present for binaries with `.await` calls.
- **Future execution**: Warn if a `Future` is created but not `.await`ed or `spawn`ed.
- **Trait analysis**: Recommend native `async fn` in traits and suggest `async-trait` only when `dyn Trait` is detected.

## Benefits

- **Scalability**: Handle tens of thousands of concurrent I/O-bound tasks with minimal OS threads.
- **Performance**: Non-blocking I/O maximizes CPU utilization by performing other work while waiting.
- **Ergonomics**: `async/.await` provides a sequential-looking control flow for asynchronous logic.
- **Composability**: `Future`s can be easily combined and managed using combinators and structured concurrency.

## Examples

### ✅ CORRECT: Complete Async Application with Tokio

```rust
use tokio::time::{self, Duration};
use anyhow::Result;

async fn fetch_resource(name: &str) -> Result<String> {
    println!("Fetching resource: {}", name);
    time::sleep(Duration::from_secs(1)).await;
    Ok(format!("{} data", name))
}

#[tokio::main]
async fn main() -> Result<()> {
    let start = time::Instant::now();

    // Run two fetch operations concurrently
    let (res1, res2) = tokio::join!(
        fetch_resource("users"),
        fetch_resource("products")
    );

    println!("Fetched users: {:?}", res1?);
    println!("Fetched products: {:?}", res2?);

    println!("Total time elapsed: {:?}", start.elapsed());
    Ok(())
}
```

### ❌ INCORRECT: Blocking and Inefficient Async Code

```rust
use std::thread;
use std::time::Duration;

// ❌ Blocking function, not async
fn fetch_resource_blocking(name: &str) -> String {
    println!("Fetching resource: {}", name);
    thread::sleep(Duration::from_secs(1)); // Blocks the thread
    format!("{} data", name)
}

// ❌ No runtime, not async main
fn main() {
    let start = std::time::Instant::now();

    // ❌ Sequential and blocking calls
    let res1 = fetch_resource_blocking("users");
    let res2 = fetch_resource_blocking("products");

    println!("Fetched users: {:?}", res1);
    println!("Fetched products: {:?}", res2);

    // Total time will be ~2 seconds instead of ~1 second
    println!("Total time elapsed: {:?}", start.elapsed());
}
```

## References

- [The Rust Async Book](https://rust-lang.github.io/async-book/)
- [Tokio Tutorial](https://tokio.rs/tokio/tutorial)
- [The `Future` Trait](https://doc.rust-lang.org/std/future/trait.Future.html)
- [Async `fn` in traits (Rust Blog)](https://blog.rust-lang.org/2023/12/21/async-fn-rpit-in-traits.html)
- [`async-trait` Crate (for `dyn Trait` support)](https://crates.io/crates/async-trait)