# Gloton Rust CLI conventions

This guide applies to Gloton's current binary parser, user-visible help and diagnostics, manifest/lockfile changes, and CLI behavior tests. Normative agent obligations live in [`.ai/harness/rules/rust/cli-clap.md`](../../../.ai/harness/rules/rust/cli-clap.md); this file explains the human rationale and examples.

## Command boundary

Gloton uses Clap derive for its command grammar. Keep commands, arguments, and bounded choices typed. Do not introduce a second manual `std::env::args` parser beside Clap.

Help text, stdout, stderr, and process exit status are public behavior. Test those at the executable boundary. Avoid tests that merely repeat struct fields or parser wiring.

## Dependencies and architecture

Add a dependency or feature only when current code consumes it and its failure behavior is understood. The present crate has no async runtime, FFI, observability stack, profiler, benchmark harness, workspace, persistence layer, or provider adapter. Add focused guidance with the first real consumer instead of keeping speculative rules active.

`Cargo.lock` is committed because Gloton is a binary. The checked-in toolchain, manifest, lockfile, Rustfmt configuration, Justfile, and CI workflow form one versioned contract.

## Mechanical policy

Rustfmt owns whitespace and line width. The compiler and Clippy own executable lint and safety checks. `Cargo.toml` and `rust-toolchain.toml` own editions, versions, components, and unsafe-code policy. Do not restate mutable version numbers as prose requirements.

Use the repository task surface:

```sh
just fmt-check
just lint
just test
just ci
```

## Applicability evidence

Checked 2026-09-13:

- [Rust 1.98.1](https://blog.rust-lang.org/2026/09/03/Rust-1.98.1/) is the pinned compiler release.
- [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html) defines edition, Rust version, resolver, and package metadata.
- [Clap derive reference](https://docs.rs/clap/latest/clap/_derive/) defines the parser pattern used by the binary.
- [Rust Style Guide](https://doc.rust-lang.org/style-guide/) delegates formatting to Rustfmt defaults.

Refresh these sources when the corresponding checked-in owner changes. The executable files and `just ci` remain the runtime truth.
