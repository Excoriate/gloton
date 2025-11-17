---
description: "Enforce best practices for workspace-level dependency management including workspace inheritance, shared dependencies, and path dependencies"
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-dependency-specification.md"
  - "./rust-dependency-management.md"
deprecated: false
globs: ["**/*.rs", "**/Cargo.toml"]
alwaysApply: true
---

# Rust Workspace Dependency Management Standards

## Cohesion Principle

**Why These Aspects Belong Together:**

This rule unifies **multi-crate dependency coordination** concerns in Rust workspaces:

1. **Workspace Structure** - Organizing multiple related crates under a single workspace root.
2. **Workspace Dependency Inheritance** - Sharing dependency versions and metadata across workspace members.
3. **Path Dependencies** - Referencing local crates within the workspace.
4. **Shared Build Configuration** - Coordinating profiles, features, and build settings.
5. **Resolver Version** - Defining the dependency resolution algorithm for the workspace.

These aspects are tightly coupled because they all govern **HOW dependencies are coordinated across multiple crates in a workspace**. Workspace structure defines the organizational hierarchy, inheritance ensures version consistency, path dependencies enable inter-crate references, shared configuration reduces duplication, and the resolver version ensures a consistent dependency resolution strategy. Together, they form the complete multi-crate dependency coordination strategy.

**Separation Rationale:**

- **Dependency Specification** (separate rule) handles single-crate concerns: version syntax, features, attributes.
- **Dependency Management** (separate rule) handles runtime concerns: resolution, locking, updates, audits.

## Description

Rust workspaces enable organizing related crates with shared dependencies, reducing duplication and ensuring version consistency. This rule enforces best practices for workspace organization, dependency inheritance, path dependencies, coordinated build configuration, and setting the resolver version.

## Rule

### 1. Workspace Structure and `resolver`

**Organize related crates under a workspace root and specify the resolver version.**

```toml
# ✅ CORRECT: Root Cargo.toml defines the workspace and resolver
[workspace]
members = [
    "core",
    "cli",
    "web",
]
resolver = "2" # Use the latest resolver for better dependency management

[workspace.package]
authors = ["Your Name <you@example.com>"]
edition = "2021"
license = "MIT"

[workspace.dependencies]
# Shared dependencies go here
tokio = { version = "1", features = ["full"] }
```

- **`resolver = "2"`**: The version 2 resolver, introduced in Rust 1.51, improves how Cargo handles feature unification and dependencies, leading to more predictable and efficient builds. It should be the default for all new workspaces.

### 2. Workspace Dependency Inheritance

**Define shared dependencies at the workspace level to ensure consistency.**

```toml
# ✅ CORRECT: Member crate inheriting from the workspace
# File: core/Cargo.toml
[package]
name = "project-core"
version = "0.1.0"
edition.workspace = true # Inherits from [workspace.package]

[dependencies]
# Inherits the version and features from the workspace
tokio.workspace = true
```

### 3. Path Dependencies

**Use path dependencies for references between crates within the same workspace.**

```toml
# ✅ CORRECT: CLI crate depends on the core library via a path
# File: cli/Cargo.toml
[dependencies]
project-core = { path = "../core" }
```

### 4. Shared Build Configuration

**Coordinate build profiles at the workspace level to maintain consistency.**

```toml
# ✅ CORRECT: Workspace-level build profiles
# File: Cargo.toml (workspace root)
[profile.release]
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"
```

### 5. `Cargo.lock` Management

**Maintain a single `Cargo.lock` at the workspace root and commit it to version control.** This ensures that all members of the workspace, as well as all developers on the team, use the exact same versions of all dependencies.

## Implementation

**Cargo Workspace Commands:**

- `cargo build --workspace`: Build all members.
- `cargo test --workspace`: Test all members.
- `cargo run --bin <binary_name>`: Run a specific binary crate.
- `cargo check --workspace`: Check all members without building.

## Benefits

1. **Version Consistency**: All crates in the workspace use the same dependency versions.
2. **Build Efficiency**: Shared dependencies are compiled only once.
3. **Reduced Duplication**: Centralized dependency and metadata management.
4. **Logical Organization**: Keeps related crates grouped together.

## Examples

### ✅ CORRECT: Complete Workspace Configuration

```toml
# File: Cargo.toml (workspace root)
[workspace]
members = ["core", "cli"]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"

[workspace.dependencies]
tokio = "1"
serde = { version = "1.0", features = ["derive"] }

[profile.release]
lto = true
```

```toml
# File: core/Cargo.toml
[package]
name = "project-core"
version.workspace = true
edition.workspace = true

[dependencies]
tokio.workspace = true
```

```toml
# File: cli/Cargo.toml
[package]
name = "project-cli"
version.workspace = true
edition.workspace = true

[dependencies]
project-core = { path = "../core" }
tokio.workspace = true
serde.workspace = true
```

### ❌ INCORRECT: Poor Workspace Organization

```toml
# ❌ Missing resolver field, which can lead to older, less efficient dependency resolution.
[workspace]
members = ["core", "cli"]

# ❌ No [workspace.dependencies], leading to duplication and potential version conflicts.
```

## Related Rules

- **[rust-dependency-specification.md](./rust-dependency-specification.md)**: Covers the syntax for specifying dependencies.
- **[rust-dependency-management.md](./rust-dependency-management.md)**: Focuses on the lifecycle of dependencies.

## References

- [The Cargo Book: Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [The Cargo Book: The `resolver` field](https://doc.rust-lang.org/cargo/reference/resolver.html)
