---
description: "Enforce proper dependency specification syntax in Cargo.toml including version constraints, feature flags, and optional dependencies"
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-dependency-management.md"
  - "./rust-workspace-dependencies.md"
deprecated: false
globs: ["**/*.rs", "**/Cargo.toml"]
alwaysApply: true
---

# Rust Dependency Specification Standards

## Cohesion Principle

**Why These Aspects Belong Together:**

This rule unifies **dependency declaration syntax** concerns in Cargo.toml:

1. **Version Constraint Syntax** - Specifying exact dependency versions with semantic versioning operators.
2. **Feature Flag Declaration** - Configuring optional functionality and feature dependencies.
3. **Dependency Attributes** - Controlling dependency compilation with `default-features`, `optional`, and `features` attributes.
4. **Dependency Types** - Differentiating between main, development, and build-time dependencies.

These aspects are tightly coupled because they all define **HOW dependencies are declared** in Cargo.toml manifests. Version constraints determine which package versions are acceptable, features control which functionality is enabled, attributes modify dependency compilation behavior, and dependency types segregate dependencies based on their role in the build process. Together, they form the complete specification syntax for declaring external dependencies in Rust projects.

**Separation Rationale:**
- **Dependency Management** (separate rule) handles runtime concerns: resolution, locking, updates, audits.
- **Workspace Dependencies** (separate rule) handles multi-crate organization: workspace inheritance, path dependencies.

## Description

Proper dependency specification in Cargo.toml ensures reproducible builds, security through version control, and explicit feature management. This rule enforces best practices for dependency syntax, version constraints, feature flag configuration, and the correct use of dependency sections (`[dependencies]`, `[dev-dependencies]`, `[build-dependencies]`).

**Core Requirements:**
- Use specific semantic version constraints (avoid wildcards `*` and open-ended `>=`).
- Explicitly declare required features for dependencies.
- Use `[dev-dependencies]` for testing, examples, and benchmarking.
- Use `[build-dependencies]` for code generation or other build-time needs.
- Use `default-features = false` when only specific features are needed.

**Rationale:**
- **Reproducibility**: Caret (`^`) and tilde (`~`) version constraints prevent unexpected breakage while allowing compatible updates.
- **Security**: Specific version ranges allow security patches while preventing breaking changes.
- **Build Optimization**: Separating dependency types reduces compilation time and final binary size.
- **Clarity**: Explicit feature declarations and dependency types document the project's structure and needs.

## Rule

### 1. Version Constraint Syntax

**Use semantic versioning with caret (`^`) or tilde (`~`) operators:**

```toml
# ✅ CORRECT: Caret allows compatible updates (e.g., 1.28.0 up to <2.0.0)
tokio = "^1.28"

# ✅ CORRECT: Tilde allows patch-level updates (e.g., 0.10.0 up to <0.11.0)
env_logger = "~0.10"

# ✅ CORRECT: Exact version for critical dependencies to prevent any changes.
openssl = "=1.1.1"

# ❌ INCORRECT: Wildcard allows any version, breaking reproducibility.
tokio = "*"

# ❌ INCORRECT: Open-ended constraint is a security risk.
serde = ">=1.0"
```

### 2. Feature Flag Declaration

**Explicitly specify required features and group related flags:**

```toml
[dependencies]
# ✅ CORRECT: Specify only needed features.
tokio = { version = "1.28", features = ["rt-multi-thread", "net", "time"] }

# ✅ CORRECT: Disable default features when not all are needed.
serde = { version = "1.0", default-features = false, features = ["derive"] }

[features]
# ✅ CORRECT: Group related features with clear names.
default = ["cli"]
cli = ["dep:clap"]
async-support = ["tokio/macros", "tokio/rt"]
```

### 3. Dependency Sections

**Use the appropriate section for each dependency:**

- **`[dependencies]`**: For dependencies required to build and run the crate.
- **`[dev-dependencies]`**: For dependencies only needed for development (e.g., tests, examples, benchmarks). These are not included in dependent crates.
- **`[build-dependencies]`**: For dependencies needed only by the build script (`build.rs`).

```toml
[dependencies]
# Main application dependencies
serde = "1.0"

[dev-dependencies]
# Dependencies for testing and benchmarking
criterion = "0.5"
mockito = "1.1"

[build-dependencies]
# Dependency for code generation at build time
bindgen = "0.69"
```

### 4. Platform-Specific Dependencies

**Use `target` configuration for dependencies that are platform-specific:**

```toml
[target.'cfg(unix)'.dependencies]
nix = { version = "0.26", features = ["signal", "process"] }

[target.'cfg(windows)'.dependencies]
winapi = { version = "0.3", features = ["winuser", "consoleapi"] }
```

### 5. Renaming Dependencies

**Use the `package` key to rename a dependency. This is useful to avoid name conflicts or to use a more convenient name.**

```toml
[dependencies]
# Renaming the 'serde' crate to 'serde_lib' in the code
serde_lib = { package = "serde", version = "1.0" }
```

### 6. Git and Path Dependencies

**Use Git dependencies to use a crate from a Git repository, and path dependencies for local, unpublished crates.**

```toml
[dependencies]
# From a git repository
rand = { git = "https://github.com/rust-random/rand.git", branch = "main" }

# From a local path
my-local-crate = { path = "../my-local-crate" }
```

**NOTE on Workspaces**: For managing dependencies in a multi-crate project, consider using a Cargo workspace. See [rust-workspace-dependencies.md](./rust-workspace-dependencies.md) for more details.

## Implementation

**Cursor IDE Integration:**
- Validate `Cargo.toml` syntax and version constraints.
- Suggest moving dependencies to `[dev-dependencies]` or `[build-dependencies]` where appropriate.
- Warn about wildcard (`*`) or open-ended (`>=`) version specifications.

**Cargo Tooling:**
- `cargo check`: Validates `Cargo.toml` syntax.
- `cargo tree`: Visualizes the dependency graph, helping to identify where dependencies are used.

## Benefits

- **Reproducible Builds**: Ensures that builds are consistent across different environments.
- **Security**: Controlled versioning reduces the risk of pulling in vulnerable code.
- **Build Performance**: Separating dependency types leads to faster compile times and smaller binaries.
- **Clarity**: A well-organized `Cargo.toml` makes the project's dependencies and structure clear.

## Examples

### ✅ CORRECT: Complete Cargo.toml with Best Practices

```toml
[package]
name = "web-service"
version = "0.1.0"
edition = "2021"

[dependencies]
# Async runtime with specific features
tokio = { version = "1.28", features = ["rt-multi-thread", "net", "time"] }
# Serialization
serde = { version = "1.0", features = ["derive"] }
# Web framework without default TLS (using rustls)
actix-web = { version = "4.3", default-features = false, features = ["macros", "compress-gzip"] }
# Renamed dependency
json-parser = { package = "serde_json", version = "1.0" }
# Git dependency
rand = { git = "https://github.com/rust-random/rand.git", branch = "main" }


[dev-dependencies]
# Testing framework
tokio-test = "0.4"
criterion = { version = "0.5", features = ["html_reports"] }

[build-dependencies]
# For build-time code generation
bindgen = "0.69"

[features]
default = []
full = ["actix-web/macros"]
```

### ❌ INCORRECT: Poor Dependency Specification

```toml
[package]
name = "bad-service"
version = "0.1.0"

[dependencies]
# ❌ Wildcard version
tokio = "*"
# ❌ Open-ended constraint
serde = ">=1.0"
# ❌ Unnecessary "full" feature, bloating the build
sqlx = { version = "0.7", features = ["full"] }
# ❌ Test dependency in main dependencies
criterion = "0.5"
```

## Related Rules

- **[rust-dependency-management.md](./rust-dependency-management.md)**: Covers the lifecycle of dependencies, including resolution, locking, and updates.
- **[rust-workspace-dependencies.md](./rust-workspace-dependencies.md)**: Focuses on managing dependencies in a multi-crate workspace.

## References

- [The Cargo Book: Specifying Dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [The Cargo Book: Features](https://doc.rust-lang.org/cargo/reference/features.html)
- [Semantic Versioning](https://semver.org/)
