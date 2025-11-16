---
description: "Enforce best practices for building command-line interfaces using the clap crate including command structure, argument handling, and user experience"
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-error-handling.md"
  - "./rust-testing.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust CLI Best Practices with clap

## Cohesion Principle

**Why These Aspects Belong Together:**

Building a command-line interface (CLI) with `clap` involves a cohesive set of practices that together create a robust and user-friendly application. This includes:

1.  **Command and Argument Structure**: Defining the CLI's commands, subcommands, and arguments, which forms the core of the user interface.
2.  **Parsing and Validation**: `clap` handles the parsing of command-line input and validates it against the defined structure, ensuring that the application receives correct and expected input.
3.  **User Experience (UX)**: Automatically generating help messages, version information, and error messages, which are integral to a good user experience.
4.  **Derive vs. Builder API**: While `clap` offers two APIs, the derive API is the modern, idiomatic choice for its conciseness and ease of use.

These components are interdependent; a well-structured CLI is of little use without proper parsing and validation, and a good user experience is built upon a clear command structure and helpful feedback.

## Description

This rule enforces best practices for building command-line interfaces using the `clap` crate. It emphasizes the use of the derive API for defining a clear and hierarchical command structure, proper argument handling, and creating a positive user experience with helpful error messages and documentation.

## Rule

### 1. Use the Derive API for Command Structure

**MANDATORY**: Use `clap`'s derive macros (`#[derive(Parser)]`) to define the CLI structure. This approach is more declarative, concise, and less error-prone than the builder API.

```rust
use clap::Parser;

/// A simple CLI to greet someone.
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// The name of the person to greet
    #[arg(short, long)]
    name: String,

    /// Number of times to greet
    #[arg(short, long, default_value_t = 1)]
    count: u8,
}

fn main() {
    let args = Args::parse();
    for _ in 0..args.count {
        println!("Hello, {}!", args.name);
    }
}
```

### 2. Organize with Subcommands

**MANDATORY**: For CLIs with multiple distinct actions, use subcommands to create a clear, hierarchical structure.

```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Adds a new item
    Add {
        #[arg(short, long)]
        name: String,
    },
    /// Removes an item
    Remove {
        #[arg(short, long)]
        name: String,
    },
}

fn main() {
    let cli = Cli::parse();
    match &cli.command {
        Commands::Add { name } => {
            println!("Adding item: {}", name);
        }
        Commands::Remove { name } => {
            println!("Removing item: {}", name);
        }
    }
}
```

### 3. Provide a Good User Experience

**MANDATORY**: Enhance the user experience by providing clear help messages, version information, and author details.

- Use doc comments (`///`) on structs and fields to automatically generate help messages.
- Use the `#[command(author, version, about)]` attribute to provide top-level information.

### 4. Use Value Enums for Predefined Choices

**MANDATORY**: For arguments that accept a fixed set of values, use `ValueEnum` to provide validation and shell completion.

```rust
use clap::{Parser, ValueEnum};

#[derive(Parser)]
struct Cli {
    /// The log level
    #[arg(short, long, value_enum, default_value_t = LogLevel::Info)]
    log_level: LogLevel,
}

#[derive(ValueEnum, Clone, Debug)]
enum LogLevel {
    Debug,
    Info,
    Warn,
    Error,
}
```

## Implementation

Cursor IDE and linters like `clippy` can enforce these practices by:
- **Detecting Manual Parsing**: Flagging manual parsing of `std::env::args()` and suggesting the use of `clap`.
- **Validating Derive Macros**: Ensuring that structs used for parsing have the `#[derive(Parser)]` attribute.
- **Checking for Documentation**: Warning about missing doc comments on public commands and arguments.

## Benefits

- **User-Friendly**: Automatically generated help messages and validation lead to a better user experience.
- **Maintainable**: The declarative nature of the derive API makes the CLI structure easy to read and modify.
- **Robust**: `clap` handles the complexities of argument parsing, reducing the chance of bugs in user input handling.
- **Modern**: Follows the current best practices of the Rust community for CLI development.

## Examples

### ✅ CORRECT: Comprehensive CLI with Subcommands

```rust
use clap::{Parser, Subcommand};
use std::path::PathBuf;

/// A fictional versioning CLI
#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    /// Sets a custom config file
    #[arg(short, long, value_name = "FILE")]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Clones a repository
    Clone {
        /// The remote repository to clone from
        remote: String,
    },
    /// Pushes changes to a remote
    Push {
        /// The remote to push to
        remote: String,
    },
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Clone { remote } => {
            println!("Cloning from '{}'", remote);
        }
        Commands::Push { remote } => {
            println!("Pushing to '{}'", remote);
        }
    }
}
```

### ❌ INCORRECT: Manual Argument Parsing

```rust
// ❌ Manual parsing is verbose, error-prone, and lacks features.
fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 {
        println!("Hello, {}!", args[1]);
    } else {
        println!("Please provide a name.");
    }
}
```

## References

- [`clap` Documentation](https://docs.rs/clap/latest/clap/)
- [`clap` Derive Tutorial](https://docs.rs/clap/latest/clap/_derive/_tutorial/index.html)
- [Command Line Interface Guidelines](https://clig.dev/)