# Gloton CLI - Rust/Cargo Task Runner

set shell := ["bash", "-uc"]

# Display available recipes
default:
    @just --list

# Build the project in debug mode
build:
    cargo build

# Build the project in release mode
build-release:
    cargo build --release

# Run the CLI (hello command by default)
run *ARGS:
    cargo run -- {{ARGS}}

# Run with hello command example
hello NAME="World":
    cargo run -- hello --name {{NAME}}

# Check code without building
check:
    cargo check

# Run all tests
test:
    cargo test

# Format code with rustfmt
fmt:
    cargo fmt

# Check formatting without making changes
fmt-check:
    cargo fmt -- --check

# Run clippy linter
clippy:
    cargo clippy --all-targets --all-features -- -D warnings

# Clean build artifacts
clean:
    cargo clean

# Install the binary locally
install:
    cargo install --path .

# Full quality check: fmt, clippy, test, build
ci: fmt-check clippy test build
    @echo "✅ All checks passed!"

# Development workflow: format, check, run
dev: fmt check
    cargo run -- hello

# Install pre-commit hooks
pre-commit-install:
    pre-commit install
    @echo "✅ Pre-commit hooks installed!"

# Run pre-commit hooks on all files
pre-commit-run:
    pre-commit run --all-files

# Update pre-commit hooks to latest versions
pre-commit-update:
    pre-commit autoupdate

# Uninstall pre-commit hooks
pre-commit-uninstall:
    pre-commit uninstall
    @echo "✅ Pre-commit hooks uninstalled!"
