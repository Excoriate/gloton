---
title: "Rust Cargo and Dependency Management Best Practices"
description: "DEPRECATED - Split into rust-dependency-specification.md, rust-dependency-management.md, and rust-workspace-dependencies.md"
globs: ["**/Cargo.toml"]
alwaysApply: false
deprecated: true
deprecation_notice: "This rule has been split into three cohesive rules for better organization. Use the new rules instead."
replaced_by:
  - "./rust-dependency-specification.md"
  - "./rust-dependency-management.md"
  - "./rust-workspace-dependencies.md"
---

# ⚠️ DEPRECATED - Use New Split Rules

**This rule has been deprecated and split into three focused rules:**

1. **[rust-dependency-specification.md](./rust-dependency-specification.md)** - Cargo.toml dependency syntax, version constraints, feature flags
2. **[rust-dependency-management.md](./rust-dependency-management.md)** - Dependency resolution, version locking, updates, security audits
3. **[rust-workspace-dependencies.md](./rust-workspace-dependencies.md)** - Workspace-level dependency management and inheritance

**Migration:**

- Review the three new rules to understand the reorganization
- Update any references to this file to point to the appropriate new rule
- This file is preserved for backward compatibility but will not be updated

---

## Original Content (Preserved for Reference)

## Description

This rule enforces best practices for Cargo and dependency management in Rust projects.

## Rule

- **Pattern**: `Cargo.toml`
- **Severity**: Warning
- **Category**: Dependencies

## Checks

1. **Dependency Management**
   - Use specific version constraints
   - Avoid using `*` or `>=` for versions
   - Use workspace dependencies when appropriate
   - Document dependency purposes

2. **Feature Flags**
   - Use feature flags for optional functionality
   - Document feature requirements
   - Use `default-features = false` when appropriate
   - Group related features

3. **Workspace Organization**
   - Use workspaces for related crates
   - Share common dependencies
   - Use path dependencies for local crates
   - Organize crates logically

4. **Build Configuration**
   - Use appropriate profiles
   - Configure build scripts properly
   - Use conditional compilation
   - Document build requirements

## Examples

### Good

```toml
[package]
name = "my-project"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <your.email@example.com>"]
description = "A well-documented project"
license = "MIT"

[dependencies]
# Use specific versions with caret
tokio = { version = "1.28", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
log = "0.4"
env_logger = "0.10"

# Optional features
my-crate = { version = "0.5", optional = true }

[features]
default = ["my-crate"]
# Group related features
async = ["tokio/async"]
json = ["serde/json"]

[workspace]
members = [
    "core",
    "cli",
    "web"
]

[profile.release]
lto = true
codegen-units = 1
panic = "abort"

[build-dependencies]
cc = "1.0"
```

### Bad

```toml
[package]
name = "bad-project"
version = "0.1.0"

[dependencies]
# Bad: Using wildcard version
tokio = "*"
# Bad: Using >= for version
serde = ">=1.0"
# Bad: Missing feature specification
log = "0.4"

# Bad: Unorganized features
[features]
feature1 = []
feature2 = []
feature3 = []

# Bad: Missing workspace organization
[workspace]
members = ["*"]
```

## Implementation

Cursor IDE and cargo tools should enforce these practices through:

- Automated dependency version validation
- Workspace structure linting
- Feature flag organization checks
- Build profile optimization suggestions
- Cargo.toml syntax validation

## Benefits

Proper dependency management ensures:

- **Reproducible builds**: Specific version constraints prevent unexpected breakage
- **Security through version control**: Avoid vulnerable dependency versions
- **Efficient dependency resolution**: Workspace organization reduces duplication
- **Clear project organization**: Logical crate structure improves maintainability
- **Optimal build performance**: Profile configuration reduces compile times

## References

- [Cargo Book](https://doc.rust-lang.org/cargo)
- [Cargo.toml Reference](https://doc.rust-lang.org/cargo/reference/manifest.html)
- [Rust Edition Guide](https://rust-lang.github.io/edition-guide)
