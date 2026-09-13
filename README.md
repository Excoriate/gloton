# Gloton

> Keep a clear view of the repositories you have cloned across Git hosting platforms.

[![CI](https://github.com/Excoriate/gloton/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Excoriate/gloton/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/Excoriate/gloton)](LICENSE)

> [!IMPORTANT]
> Gloton is an early-stage Rust CLI. Repository discovery, remote comparison, and synchronization commands are planned, not implemented. The current binary provides a stable parser boundary with help, version, and explicit rejected-input behavior.

## Why Gloton

Repository collections tend to spread across GitHub organizations, Azure DevOps projects, and local directories. Gloton is intended to make that collection inspectable: what is cloned, which remote moved, and which repositories you choose to update.

The scaffold deliberately does less today. It establishes the command, toolchain, tests, contribution loop, CI, and repository policy without inventing provider or synchronization behavior before those contracts are designed.

## Current behavior

```text
$ gloton --help
Organize repository collections across Git hosting platforms
```

The binary currently supports:

- `--help` for the implemented command boundary;
- `--version` for package identity;
- clear exit-code-2 diagnostics for missing or unknown input.

A token such as `sync` is rejected because no synchronization command exists yet.

## Get started

Install these prerequisites once:

- [Git](https://git-scm.com/);
- [rustup](https://rustup.rs/), using its standard Cargo-home proxy installation;
- [Just](https://just.systems/), version 1.55.0 or newer.

Then use Just for repository work:

```sh
git clone git@github.com:Excoriate/gloton.git
cd gloton
just setup
just ci
just run --help
```

`rust-toolchain.toml` selects Rust 1.98.1 with Rustfmt and Clippy. `just doctor` prints the effective executables and versions when a local PATH is in doubt.

## Developer commands

Run `just` with no arguments to see the supported task surface.

| Command | Purpose |
|---|---|
| `just setup` | Prepare the pinned toolchain and fetch locked dependencies. |
| `just doctor` | Show effective Just, rustup, compiler, Cargo, Rustfmt, and Clippy identities. |
| `just fmt` | Format Rust source. |
| `just fmt-check` | Check formatting without changing source. |
| `just lint` | Run strict Clippy across all targets and features. |
| `just test` | Run the test suite, including CLI and repository-rule contracts. |
| `just check` | Type-check all targets and features. |
| `just build` | Build the debug binary. |
| `just run <args>` | Run Gloton with the supplied arguments. |
| `just install` | Install Gloton from this checkout. |
| `just ci` | Run the same non-mutating gate used by GitHub Actions. |

Normal development commands are intentionally routed through this file. Tool installation and the initial Git clone are the only bootstrap exceptions.

## Repository contract

- **One toolchain selector.** `rust-toolchain.toml` owns the compiler and components used by local tasks and CI.
- **One task graph.** Just owns setup, checks, execution, and installation; CI calls the same recipes.
- **Observable CLI behavior.** Tests assert process status and stdout/stderr instead of parser wiring.
- **One agent-policy owner.** Canonical context and rules live in `.ai/harness/`; root and client files are generated projections.
- **No speculative subsystems.** Provider adapters, persistence, networking, and update policy arrive with implemented consumers, not placeholder modules.

The human Rust/CLI conventions are in [`docs/styleguides/rust/rust-cli-clap.md`](docs/styleguides/rust/rust-cli-clap.md). Agent-facing obligations are canonical under [`.ai/harness/rules/`](.ai/harness/rules/).

## Planned direction

Future design work may introduce repository inventory, GitHub and Azure DevOps discovery, remote-state comparison, and explicitly selected updates. Those capabilities are not part of version 0.1.0 until their command, safety, identity, and failure contracts are implemented and tested.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the supported workflow and scope rules.

## License

Gloton is available under the [MIT License](LICENSE).
