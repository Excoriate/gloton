---
name: ddd-project
description: Gloton project identity, executable boundary, stack, and authoritative local surfaces.
type: ddd
alwaysApply: true
---
<!-- CONTINUOUSLY ENRICHED — update when project structure or stack changes -->

# Gloton project intelligence

## Identity

Gloton is an early-stage Rust command-line application intended to organize repository collections across Git hosting platforms. Version 0.1.0 implements only the process parser boundary: help, version, missing-input usage, and rejection of unknown input.

## Stack and owners

| Concern | Canonical owner | Consumer |
|---|---|---|
| Compiler and components | `rust-toolchain.toml` | rustup, local Just recipes, GitHub Actions |
| Package/dependencies/safety | `Cargo.toml` and `Cargo.lock` | Cargo |
| Developer task graph | `Justfile` | contributors and GitHub Actions |
| Process grammar | `src/main.rs` | the `gloton` binary |
| Public CLI behavior | `tests/cli.rs` | Cargo test runner |
| Agent policy | `.ai/harness/` | generated root/client carriers |
| Human setup and scope | `README.md`, `CONTRIBUTING.md` | contributors |

## Boundaries

`src/main.rs` has no repository, provider, network, filesystem, persistence, or synchronization effect. Add those concepts to this document only with their first implemented code and observable failure contract.

## Startup route

Read `.ai/harness/ddd-ubiquitous-language.md`, `.ai/harness/context/pattern-map.md`, scoped lessons, and matching `.ai/harness/CONTEXT.md` routes before changing a boundary.

## Last updated

2026-09-13 during the Gloton repository retrofit.
