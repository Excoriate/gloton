---
title: "Gloton: Required Context & References"
description: "Gloton-specific web and local references for LLM context engineering"
category: "context-engineering"
type: "reference"
version: "3.0"
audience: "llm"
updated: "2025-11-17"
---

# Gloton: Required Context & References

Curated references mapped to Gloton's specific implementation needs. This is a context-engineering document, not a general reference list.

## Language Fundamentals

| Reference | URL | Required For |
|-----------|-----|--------------|
| **Rust Book: Ownership** | <https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html> | Ownership model, borrowing rules, memory safety without GC, move semantics |
| **Rust Book: Lifetimes** | <https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html> | Lifetime annotations, generic lifetimes, lifetime elision rules, 'static lifetime |
| **Rust Book: Error Handling** | <https://doc.rust-lang.org/book/ch09-00-error-handling.html> | Result<T,E>, Option<T>, panic! vs recoverable errors, ? operator |
| **Rust Book: Pattern Matching** | <https://doc.rust-lang.org/book/ch06-02-match.html> | Match expressions, exhaustive patterns, if let syntax, pattern destructuring |
| **Std: Collections** | <https://doc.rust-lang.org/std/collections/> | Vec, HashMap, HashSet, VecDeque, BTreeMap collection types and APIs |
| **Std: I/O** | <https://doc.rust-lang.org/std/io/> | Read, Write, BufReader, BufWriter traits for buffered I/O operations |
| **Std: Filesystem** | <https://doc.rust-lang.org/std/fs/> | File, read_to_string, create_dir_all, metadata, symlink filesystem operations |
| **Std: Process** | <https://doc.rust-lang.org/std/process/> | Command, Stdio, Child for spawning and managing external processes |
| **[Ownership & Borrowing](../../styleguides/rust/rust-ownership-borrowing.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-ownership-borrowing.md#rule) | Memory safety without GC, lifetime management, zero-copy string handling, buffer reuse
| **[Type System & Generics](../../styleguides/rust/rust-type-system-generics.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-type-system-generics.md#rule) | Generic provider abstractions, trait bounds, type parameters, zero-cost abstractions |

## Build System & Dependencies

| Reference | URL | Required For |
|-----------|-----|--------------|
| **Cargo: Workspaces** | <https://doc.rust-lang.org/cargo/reference/workspaces.html> | Multi-package workspace configuration, virtual manifests, workspace.package, workspace.dependencies inheritance |
| **Cargo: Dependency Resolution** | <https://doc.rust-lang.org/cargo/reference/resolver.html> | Dependency graph algorithms, version selection, feature unification, resolver v2 behavior |
| **Cargo: Build Profiles** | <https://doc.rust-lang.org/cargo/reference/profiles.html> | dev/release/test profiles, opt-level, debug symbols, overflow-checks, strip configuration |
| **Cargo: Features** | <https://doc.rust-lang.org/cargo/reference/features.html> | Conditional compilation, optional dependencies, feature flag resolution, default features |
| **Cargo: Manifest Format** | <https://doc.rust-lang.org/cargo/reference/manifest.html> | Cargo.toml structure, [package], [dependencies], [dev-dependencies], [build-dependencies] sections |
| **[Cargo Dependencies](../../styleguides/rust/rust-cargo-dependencies.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-cargo-dependencies.md#rule) | Workspace dependency management, feature flag configuration, optional dependencies, dev-dependencies |
| **[Dependency Management](../../styleguides/rust/rust-dependency-management.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-dependency-management.md#rule) | Cargo.toml organization, semantic versioning, version pinning strategies, dependency updates |
| **[Dependency Specification](../../styleguides/rust/rust-dependency-specification.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-dependency-specification.md#rule) | Version range syntax, caret/tilde requirements, wildcard usage, git/path dependencies |
| **[Workspace Dependencies](../../styleguides/rust/rust-workspace-dependencies.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-workspace-dependencies.md#rule) | Multi-crate workspace layout, shared dependency versions, workspace inheritance, virtual manifests |

## CLI Interface

| Reference | URL | Required For |
|-----------|-----|--------------|
| **clap: Derive Tutorial** | <https://docs.rs/clap/latest/clap/_derive/_tutorial/index.html> | CLI argument parsing with derive macros (#[derive(Parser)]), subcommand structure, help generation, validation patterns |
| **[CLI with clap](../../styleguides/rust/rust-cli-clap.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-cli-clap.md#rule) | CLI commands (`init`, `sync`), subcommand structure, argument parsing, derive API implementation |

## Provider API Integration

| Reference | URL | Required For |
|-----------|-----|--------------|
| **reqwest** | <https://docs.rs/reqwest/latest/reqwest/> | HTTP client library for provider REST API calls, connection pooling, TLS support, async requests |
| **tokio** | <https://docs.rs/tokio/latest/tokio/> | Async runtime for concurrent operations, task spawning, async I/O, timer utilities, sync primitives |
| **serde** | <https://docs.rs/serde/latest/serde/> | Serialization/deserialization framework, JSON schema mapping, custom deserializers, derive macros |
| **serde_json** | <https://docs.rs/serde_json/latest/serde_json/> | JSON parsing for provider API responses, value manipulation, serialization to JSON strings |
| **[Async/Await](../../styleguides/rust/rust-async-await.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-async-await.md#rule) | Concurrent HTTP API calls, parallel repository operations, tokio runtime configuration |

### GitHub API

| Endpoint | URL | Required For |
|----------|-----|--------------|
| **Authentication** | <https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api?apiVersion=2022-11-28> | Personal Access Token (PAT) validation, authentication header construction, token scope verification |
| **Repositories** | <https://docs.github.com/en/rest/repos> | List organization repositories, fetch clone URLs (HTTPS/SSH), retrieve repository metadata (name, visibility, default_branch) |

### GitLab API

| Endpoint | URL | Required For |
|----------|-----|--------------|
| **Authentication** | <https://docs.gitlab.com/ee/api/rest/authentication.html> | Token-based authentication, private-token header construction, OAuth2 token flows, personal access tokens |
| **Projects** | <https://docs.gitlab.com/ee/api/projects.html> | List group/subgroup projects, fetch repository clone URLs, pagination handling |
| **Groups** | <https://docs.gitlab.com/ee/api/groups.html> | Navigate group hierarchies, discover subgroups recursively, list group projects |

### Azure DevOps API

| Endpoint | URL | Required For |
|----------|-----|--------------|
| **Authentication** | <https://learn.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/authentication-guidance> | Personal Access Token (PAT) generation, base64 encoding, Basic auth header construction |
| **Git Repositories** | <https://learn.microsoft.com/en-us/rest/api/azure/devops/git/repositories> | List project repositories, fetch clone URLs, repository properties (name, remoteUrl, project) |
| **Projects** | <https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects> | List organization projects, project metadata, project-to-repository mapping |

## State Management (Database)

| Reference | URL | Required For |
|-----------|-----|--------------|
| **SQLite: CREATE TABLE** | <https://www.sqlite.org/lang_createtable.html> | Schema design for repositories table, column types (TEXT, INTEGER, TIMESTAMP), constraints (PRIMARY KEY, NOT NULL, UNIQUE) |
| **SQLite: SELECT Query** | <https://www.sqlite.org/lang_select.html> | Query repositories, WHERE clauses, JOIN operations, ORDER BY, LIMIT for pagination |
| **SQLite: INSERT** | <https://www.sqlite.org/lang_insert.html> | Insert new repository records, INSERT OR REPLACE for upserts, bulk inserts |
| **SQLite: Transactions** | <https://www.sqlite.org/lang_transaction.html> | BEGIN, COMMIT, ROLLBACK transaction control, ACID guarantees, isolation levels |
| **rusqlite** | <https://docs.rs/rusqlite/latest/rusqlite/> | Rust SQLite bindings, parameterized queries, connection pooling, transaction management, error handling |

## Repository Operations (Git)

| Reference | URL | Required For |
|-----------|-----|--------------|
| **git2-rs** | <https://docs.rs/git2/latest/git2/> | Repository cloning, pulling updates, authentication with PATs, remote management, error handling |
| **[FFI Integration](../../styleguides/rust/rust-ffi-integration.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-ffi-integration.md#rule) | git2-rs safe bindings, C library integration (libgit2), FFI safety patterns, error conversion |

## Error Handling

| Reference | URL | Required For |
|-----------|-----|--------------|
| **anyhow** | <https://docs.rs/anyhow/latest/anyhow/> | Application-level error handling, context propagation, error chaining, simplified error management |
| **thiserror** | <https://docs.rs/thiserror/latest/thiserror/> | Custom error type definitions with derive macros, error conversions, library-level error design |
| **[Error Handling](../../styleguides/rust/rust-error-handling.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-error-handling.md#rule) | Result propagation with `?`, custom error types with thiserror, application errors with anyhow |

## Observability

| Reference | URL | Required For |
|-----------|-----|--------------|
| **[Logging Patterns](../../styleguides/rust/rust-logging-patterns.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-logging-patterns.md#rule) | Structured logging with tracing, log levels, contextual information propagation |
| **[Tracing Instrumentation](../../styleguides/rust/rust-tracing-instrumentation.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-tracing-instrumentation.md#rule) | Distributed tracing setup, span instrumentation, async task tracking, performance profiling |
| **[Observability Integration](../../styleguides/rust/rust-observability-integration.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-observability-integration.md#rule) | Integration with observability systems (Prometheus, Jaeger), metrics collection, trace export |
| **[Observability Logging](../../styleguides/rust/rust-observability-logging.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-observability-logging.md#rule) | Structured logging formats for observability platforms, JSON logging, log aggregation |

## Performance & Optimization

| Reference | URL | Required For |
|-----------|-----|--------------|
| **[Performance Optimization](../../styleguides/rust/rust-performance-optimization.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-performance-optimization.md#rule) | Parallel repository sync, bulk HTTP operations, connection pooling, async batching |
| **[Benchmarking](../../styleguides/rust/rust-benchmarking.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-benchmarking.md#rule) | Performance benchmarking with criterion, regression detection, statistical analysis |
| **[Memory Optimization](../../styleguides/rust/rust-memory-optimization.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-memory-optimization.md#rule) | Memory usage reduction, allocation patterns, buffer reuse, arena allocators |
| **[Optimization Techniques](../../styleguides/rust/rust-optimization-techniques.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-optimization-techniques.md#rule) | General optimization patterns, algorithmic improvements, data structure selection |
| **[Profiling Analysis](../../styleguides/rust/rust-profiling-analysis.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-profiling-analysis.md#rule) | Performance profiling tools (perf, flamegraph), bottleneck identification, hotspot analysis |

## Testing & Quality Assurance

| Reference | URL | Required For |
|-----------|-----|--------------|
| **rustfmt: Configuration** | <https://rust-lang.github.io/rustfmt/> | Automatic code formatting, rustfmt.toml configuration, max_width, edition settings, format_code_in_doc_comments |
| **clippy: Lint Index** | <https://rust-lang.github.io/rust-clippy/master/> | Lint checks for idiomatic patterns, performance anti-patterns, common mistakes, searchable lint catalog with examples |
| **cargo test** | <https://doc.rust-lang.org/cargo/commands/cargo-test.html> | Unit/integration test execution, test filtering, parallel test runs, CI/CD integration |
| **[Testing](../../styleguides/rust/rust-testing.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-testing.md#rule) | Unit test structure, integration test organization, mock HTTP clients, test fixtures |
| **[Documentation](../../styleguides/rust/rust-documentation.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-documentation.md#rule) | Public API documentation standards, module-level docs, doc tests, example code |

## Safety & Soundness

| Reference | URL | Required For |
|-----------|-----|--------------|
| **[Safety Guarantees](../../styleguides/rust/rust-safety-guarantees.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-safety-guarantees.md#rule) | Rust safety invariants enforcement, unsafe code audit procedures, soundness verification |
| **[Safety Unsafe](../../styleguides/rust/rust-safety-unsafe.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-safety-unsafe.md#rule) | Unsafe code usage in FFI boundaries (git2-rs), raw pointer handling, safety documentation |
| **[Unsafe Patterns](../../styleguides/rust/rust-unsafe-patterns.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-unsafe-patterns.md#rule) | Unsafe code patterns for performance-critical sections, invariant documentation, miri validation |
| **[Soundness Verification](../../styleguides/rust/rust-soundness-verification.md#rule)** | [local reference in docs/styleguides/](../../styleguides/rust/rust-soundness-verification.md#rule) | Type soundness verification, memory safety proofs, unsafe code validation with miri |
