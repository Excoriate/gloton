# Change-impact map

| Changed surface | Required companion decision | Verification |
|---|---|---|
| `src/**/*.rs`, `tests/**/*.rs`, `Cargo.toml`, `Cargo.lock` | Does public CLI, dependency, or safety prose change? | `just test`, `just lint`, then `just ci` |
| `rust-toolchain.toml`, `.rustfmt.toml` | Do manifest minimums, editor behavior, CI, or README prerequisites drift? | `just doctor`, `just fmt-check`, `just ci` |
| `Justfile` | Do README, CONTRIBUTING, or CI invoke a removed/renamed recipe? | `just --list`, `just --summary`, workflow inspection, `just ci` |
| `.ai/harness/AGENTS.md`, `rules/**`, `CONTEXT.md` | Which declared carriers must regenerate? | wrapper generator check plus `tests/harness.rs` |
| README/CONTRIBUTING/styleguide | Does prose claim unimplemented behavior or a direct normal task path? | full committed-tree semantic scan |
| `.gitignore`, `.gitattributes`, `.vscode/**` | Is a tracked/generated/editor surface now hidden or duplicated? | clean-clone file inventory and editor JSON parse |
| `.github/**` | Does hosted behavior match local Just and declared protection? | hosted run on exact SHA plus GitHub API readback |
| `.ai/harness/adrs/**` | Is this a new durable choice or a supersession? | ADR allocator and validator |
