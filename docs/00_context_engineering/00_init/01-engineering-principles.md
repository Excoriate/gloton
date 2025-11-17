---
title: "Gloton: Design Principles & Technical Guidelines"
description: "Core design principles, architectural patterns, and technical standards for Gloton development"
category: "context-engineering"
type: "definition"
version: "1.0"
audience: "llm"
updated: "2025-11-16"
---

# Gloton: Design Principles & Technical Guidelines

## Overview

This document defines the core design principles, architectural patterns, and technical standards that guide Gloton's development. These principles ensure consistency, maintainability, and alignment with the project's vision of simplicity and reliability.

## Core Design Philosophy

### Simplicity is the Ultimate Sophistication

Gloton embraces radical simplicity. Every design decision prioritizes clarity over cleverness, directness over abstraction, and maintainability over premature optimization.

**Key Tenets:**

- **YAGNI (You Aren't Gonna Need It)**: Implement only what's required now, not what might be needed later
- **Single Responsibility**: Each component does one thing exceptionally well
- **Explicit over Implicit**: Configuration, behavior, and dependencies are always explicit
- **Fail Fast, Fail Clearly**: Errors are detected early and reported with actionable context

### Idempotency by Design

All Gloton operations are safe to re-run multiple times with identical outcomes.

**Implementation:**

- `init` and `sync` commands can be executed daily without side effects
- Existing repositories are updated, not re-cloned
- State tracking prevents duplicate operations
- No destructive operations without explicit confirmation

### Progressive Enhancement

Gloton starts simple and grows capabilities incrementally without breaking existing workflows.

**Approach:**

- Core functionality (init, sync) works out-of-the-box with minimal configuration
- Advanced features (filtering, parallel execution) are opt-in via flags
- Backwards compatibility maintained across versions
- Configuration evolves without requiring migration

## Architectural Patterns

### Adapter Pattern

All external interactions use the adapter pattern, enabling flexibility and maintainability.

**Design:**

- HTTP clients (GitHub, GitLab, Azure DevOps) are adapters
- Git operations are adapters
- Database access is an adapter
- Each adapter can be swapped with alternative implementations

**Benefits:**

- **Testability**: Mock adapters for unit testing
- **Flexibility**: Replace HTTP client without changing core logic
- **Evolution**: Add new providers by implementing adapter interface
- **Isolation**: External dependencies don't leak into business logic

### Layered Architecture

Clear separation of concerns with strict dependency rules.

**Layers:**

| Layer | Components | Responsibility |
|-------|------------|----------------|
| **User Layer** | CLI interface, environment configuration | User interaction and lightweight configuration |
| **Application Layer** | Auth Manager, Sync Engine, State Management | Core business logic and orchestration |
| **Adapter Layer** | Provider HTTP clients, Git adapter | Protocol translation for external systems |
| **External Layer** | Provider APIs, local filesystem | Third-party dependencies and persistent storage |

**Dependency Rules:**

- Dependencies flow inward only: User → Application → Adapters → External
- Each layer has single, well-defined responsibility
- Cross-layer communication through explicit interfaces
- No layer bypass (strict hierarchical flow)

### State Management

Persistent state tracking using SQLite ensures reliability and idempotency.

**Implementation:**

- SQLite database tracks synchronized repositories
- Metadata stored: Provider, organization/project, local path, remote URL, sync timestamp
- State enables smart detection: new repositories (clone) vs. existing (pull)
- Atomic operations prevent partial state corruption

**Benefits:**

- **Idempotent Operations**: Safe to re-run without duplication
- **Audit Trail**: Track synchronization history
- **Resumability**: Recover from interrupted syncs
- **Efficiency**: Skip already-synchronized repositories

## Core Programming Principles

### Core Programming Languages

- [Rust](https://www.rust-lang.org/) as the primary programming language
- [SQLite](https://www.sqlite.org/) as the database for storing the state of the repositories

### Core Programming Practices for Quality and Maintainability

- All [Rust](https://www.rust-lang.org/) code must be [formatted](https://github.com/rust-lang/rustfmt) using [rustfmt](https://github.com/rust-lang/rustfmt).
- All [Rust](https://www.rust-lang.org/) code must be [linted](https://github.com/rust-lang/rust-clippy) using [clippy](https://github.com/rust-lang/rust-clippy).
- All [Rust](https://www.rust-lang.org/) code must be [tested](https://www.rust-lang.org/tools/testing) using [cargo test](https://doc.rust-lang.org/cargo/commands/cargo-test.html).
