# Rust CLI Template

A minimal, production-ready Rust CLI boilerplate with [clap](https://github.com/clap-rs/clap) for argument parsing and [just](https://github.com/casey/just) for task automation.

## Features

- ✅ **Minimal dependencies** - Only `clap` for CLI parsing
- ✅ **Modern Rust** - Edition 2021 with idiomatic patterns
- ✅ **Just recipes** - Pre-configured build, test, lint, and run tasks
- ✅ **Production-ready** - Includes formatting, linting, and CI workflows
- ✅ **Example command** - Working `hello` command to demonstrate structure

## Quick Start

### Installation

**Clone and customize:**

```sh
# Clone this template
git clone https://github.com/yourusername/yourproject.git
cd yourproject

# Update Cargo.toml with your project details
# - name
# - authors
# - description
# - repository

# Build the project
just build
```

**Or download a release binary from the [releases page](https://github.com/yourusername/yourproject/releases).**

## Usage

```console
➜  ~  gloton --help
A simple CLI tool

Usage: gloton <COMMAND>

Commands:
  hello  Say hello to the world
  help   Print this message or the help of the given subcommand(s)

Options:
  -h, --help     Print help
  -V, --version  Print version

EXAMPLE:
  gloton hello              # Output: Hello, World!
  gloton hello --name Alex  # Output: Hello, Alex!
```

### Verify installation

To verify that the CLI has been installed, do:

```bash
gloton --version
```

which should output the version if the installation was successful.

## Development

### Prerequisites

- **Rust** (edition 2021+) - Install via [rustup](https://rustup.rs/)
- **Just** (optional but recommended) - Install via `cargo install just` or `brew install just`

### Available Commands

The `Justfile` provides convenient recipes for common tasks:

```bash
# Show all available recipes
just

# Build in debug mode
just build

# Build in release mode
just build-release

# Run the CLI with arguments
just run hello --name World

# Quick hello example
just hello
just hello "Alex"

# Development workflow (format + check + run)
just dev

# Run all tests
just test

# Format code with rustfmt
just fmt

# Check formatting
just fmt-check

# Run clippy linter (strict mode)
just clippy

# Clean build artifacts
just clean

# Full CI check (fmt + clippy + test + build)
just ci

# Install binary locally
just install
```

## Project Structure

```
.
├── Cargo.toml          # Project metadata and dependencies
├── Justfile            # Task automation recipes
├── src/
│   ├── main.rs         # Entry point and command handling
│   └── cli.rs          # CLI structure and command definitions
└── README.md           # This file
```

## Customizing the Template

### Adding New Commands

1. **Define command in `src/cli.rs`:**

```rust
#[derive(Subcommand)]
pub enum Commands {
    Hello { ... },

    /// Your new command description
    YourCommand {
        /// Command argument
        #[arg(short, long)]
        arg_name: String,
    },
}
```

2. **Handle command in `src/main.rs`:**

```rust
match cli.command {
    Commands::Hello { name } => { ... },

    Commands::YourCommand { arg_name } => {
        // Your command logic here
        println!("Executing with: {}", arg_name);
    }
}
```

3. **Test it:**

```bash
just dev
```

### Adding Dependencies

Add dependencies to `Cargo.toml`:

```toml
[dependencies]
clap = { version = "4.5", features = ["derive"] }
serde = { version = "1.0", features = ["derive"] }  # Example
```

Then run:

```bash
cargo build
```

## Example

### Running the hello command

Default greeting:

```
➜  ~  gloton hello
Hello, World!
```

Custom greeting:

```
➜  ~  gloton hello --name Rustacean
Hello, Rustacean!
```

Using the short flag:

```
➜  ~  gloton hello -n Alex
Hello, Alex!
```

## Quality Checks

This template includes strict quality checks:

```bash
# All checks must pass (run this before committing)
just ci
```

Which runs:
- ✅ `cargo fmt --check` - Code formatting
- ✅ `cargo clippy -- -D warnings` - Linting (zero warnings allowed)
- ✅ `cargo test` - All tests
- ✅ `cargo build` - Compilation

## Compatibility

- **Rust**: Edition 2021 (Rust 1.56+)
- **Platforms**: macOS, Linux, Windows
- **Package Manager**: Cargo

## License

Released under the MIT License. See the bundled [LICENSE](./LICENSE) file for details.

---

## Template Checklist

When using this template for a new project:

- [ ] Update `Cargo.toml` (name, authors, description, repository)
- [ ] Update this `README.md` (replace "gloton" with your project name)
- [ ] Update `LICENSE` file with your name/organization
- [ ] Remove the example `hello` command (or keep as reference)
- [ ] Add your actual commands in `src/cli.rs` and `src/main.rs`
- [ ] Update Justfile recipes if needed
- [ ] Set up CI/CD (GitHub Actions, GitLab CI, etc.)
- [ ] Create release workflow
- [ ] Update repository URL and clone instructions above
