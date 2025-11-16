---
description: "Enforce best practices for dependency resolution, version locking, updates, and security audits using Cargo tools"
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-dependency-specification.md"
  - "./rust-workspace-dependencies.md"
deprecated: false
globs: ["**/*.rs", "**/Cargo.toml", "**/Cargo.lock"]
alwaysApply: true
---

# Rust Dependency Management Standards

## Cohesion Principle

**Why These Aspects Belong Together:**

This rule unifies **dependency lifecycle management** concerns in Rust projects:

1.  **Dependency Resolution** - How Cargo resolves compatible versions from specified constraints.
2.  **Version Locking** - Using `Cargo.lock` to ensure reproducible builds across environments.
3.  **Dependency Updates** - Managing version upgrades with `cargo update`, `cargo outdated`.
4.  **Security Audits** - Detecting vulnerable dependencies with `cargo audit`.
5.  **Policy Enforcement** - Using tools like `cargo-deny` to enforce contribution and licensing policies.

These aspects are tightly coupled because they all govern **HOW dependencies are resolved, locked, updated, and audited over time**. Resolution determines which versions are selected, locking ensures reproducibility, updates manage version evolution, audits ensure security compliance, and policy enforcement maintains legal and quality standards. Together, they form the complete lifecycle management of external dependencies from initial resolution to ongoing maintenance.

**Separation Rationale:**
- **Dependency Specification** (separate rule) handles declaration syntax: version constraints, features, attributes.
- **Workspace Dependencies** (separate rule) handles multi-crate organization: workspace inheritance, path dependencies.

## Description

Effective dependency management ensures reproducible builds, security compliance, and controlled version updates. This rule enforces best practices for `Cargo.lock` management, dependency resolution strategies, update workflows, security auditing, and policy enforcement with tools like `cargo-deny`.

## Rule

### 1. `Cargo.lock` Version Control

**Always commit `Cargo.lock` for binary projects; it's optional for libraries.**

- **Binary/Application Projects**: ALWAYS commit `Cargo.lock` to ensure reproducible deployments.
- **Library Crates**: OPTIONAL, as consumers of the library will generate their own `Cargo.lock`.
- **Workspaces**: Commit the root `Cargo.lock` for reproducibility across all workspace members.

### 2. Dependency Resolution

**Understand and manage Cargo's dependency resolution.**

- Use `cargo tree` to visualize the dependency graph.
- Use `cargo tree --duplicates` to find and resolve multiple versions of the same crate, which can increase binary size and compile times.

### 3. Controlled Dependency Updates

**Use targeted updates instead of a blanket `cargo update`.**

- **`cargo outdated`**: Use this tool to check for outdated dependencies before updating.
- **Targeted updates**: `cargo update --package <package_name>` allows for controlled, incremental updates.
- **Dry runs**: Use `cargo update --dry-run` to preview changes before applying them.

**Update Workflow:**
1.  Run `cargo outdated` to see what's new.
2.  Review changelogs for breaking changes.
3.  Update a single dependency: `cargo update -p <package_name>`.
4.  Run tests and `cargo audit`.
5.  Commit `Cargo.lock` with a descriptive message.

### 4. Security Audits

**Regularly audit dependencies for known vulnerabilities.**

- **`cargo audit`**: The standard tool for checking your dependency tree against the RustSec advisory database.
- **CI/CD Integration**: Automate security audits in your CI/CD pipeline to catch vulnerabilities early.

### 5. Policy Enforcement with `cargo-deny`

**Use `cargo-deny` to enforce policies on your dependencies.**

- **Licenses**: Ensure all dependencies have a compatible license.
- **Unmaintained Crates**: Ban dependencies that are no longer maintained.
- **Security Advisories**: Check for security vulnerabilities (integrates with RustSec).
- **Source Control**: Verify that all dependencies are sourced from trusted locations (e.g., crates.io).

**Example `deny.toml` configuration:**
```toml
[licenses]
unlicensed = "deny"
allow = ["MIT", "Apache-2.0", "BSD-3-Clause"]

[bans]
multiple-versions = "warn"
wildcards = "deny"

[advisories]
vulnerability = "deny"
unmaintained = "warn"
```

## Implementation

**Cargo Tooling:**
- `cargo update`: Updates dependencies as allowed by `Cargo.toml`.
- `cargo tree`: Shows the full dependency graph.
- `cargo install cargo-outdated`: Installs the outdated checker.
- `cargo install cargo-audit`: Installs the security auditor.
- `cargo install cargo-deny`: Installs the policy enforcement tool.

## Benefits

1.  **Reproducible Builds**: `Cargo.lock` ensures that every build uses the exact same dependency versions.
2.  **Security**: `cargo audit` and `cargo-deny` help prevent the use of vulnerable or untrustworthy code.
3.  **Stability**: Controlled updates prevent unexpected breaking changes from upstream dependencies.
4.  **Compliance**: `cargo-deny` helps ensure that your project complies with licensing and other organizational policies.

## Examples

### ✅ CORRECT: Complete Dependency Management Workflow

```bash
#!/bin/bash
# dependency-update.sh - A safe dependency update workflow

set -euo pipefail

echo "Step 1: Check for outdated dependencies"
cargo outdated

echo "Step 2: Run security and policy checks"
cargo audit
cargo deny check

echo "Step 3: Update a specific dependency"
read -p "Enter package name to update: " PACKAGE
cargo update --package "$PACKAGE"

echo "Step 4: Run tests and checks again"
cargo test --all-features
cargo audit
cargo deny check

echo "Step 5: Commit changes"
git add Cargo.toml Cargo.lock
git commit -m "Update $PACKAGE dependency"

echo "Update complete!"
```

### ❌ INCORRECT: Unsafe Dependency Management

```bash
# ❌ Updates all dependencies without review or testing.
cargo update
git commit -am "updated deps"
```

## Related Rules

- **[rust-dependency-specification.md](./rust-dependency-specification.md)**: Covers the syntax for specifying dependencies in `Cargo.toml`.
- **[rust-workspace-dependencies.md](./rust-workspace-dependencies.md)**: Focuses on managing dependencies in a multi-crate workspace.

## References

- [The Cargo Book: Dependency Resolution](https://doc.rust-lang.org/cargo/reference/resolver.html)
- [cargo-audit](https://github.com/rustsec/rustsec/tree/main/cargo-audit)
- [cargo-outdated](https://github.com/kbknapp/cargo-outdated)
- [cargo-deny](https://github.com/EmbarkStudios/cargo-deny)
