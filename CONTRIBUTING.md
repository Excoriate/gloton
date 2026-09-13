# Contributing to Gloton

Gloton is early-stage. Keep changes small, observable, and honest about what the binary implements.

## Set up

Install Git, rustup, and Just 1.55.0 or newer. From the repository root:

```sh
just setup
just doctor
just ci
```

`just doctor` must show the Rust toolchain selected by `rust-toolchain.toml`. Fix local PATH or rustup installation problems before changing repository policy to accommodate one machine.

## Development workflow

Use the root Justfile for normal work:

```sh
just fmt
just lint
just test
just check
just build
just run --help
just ci
```

Pass focused test arguments after `just test`; Just preserves their argument boundaries. Do not add a parallel script, hook framework, or documented direct build path for a task the Justfile already owns.

Before opening a change:

1. keep help text, exit status, stdout, and stderr behavior deliberate;
2. add a process-level test when the public CLI contract changes;
3. run `just fmt`, then `just ci`;
4. update README or the Rust/CLI styleguide only when the implemented behavior or durable convention changed.

## Scope

Do not add GitHub, Azure DevOps, synchronization, persistence, logging, async, or release abstractions without a current implemented consumer and a testable failure contract. Mark future behavior as planned rather than describing it as available.

Dependencies must have a direct code consumer. The pinned toolchain, manifest, lockfile, Rustfmt, Justfile, and CI workflow are one coordinated contract and should change together when required.

## Repository rules

Canonical agent context and rules live under `.ai/harness/`. Root `AGENTS.md`, root `CLAUDE.md`, and client-specific rules are generated carriers. Edit the canonical source and regenerate; never hand-edit a generated wrapper.

Human Rust/CLI guidance lives at [`docs/styleguides/rust/rust-cli-clap.md`](docs/styleguides/rust/rust-cli-clap.md).

## Pull requests

Keep pull requests focused. Explain the observable behavior changed, how `just ci` exercised it, and any remaining limitation. Do not claim a platform, provider, or release workflow that the committed repository does not exercise.
