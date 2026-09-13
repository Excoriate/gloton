# Gloton pattern map

## Current architecture

```text
process argv -> Clap derive parser in src/main.rs -> help/version or usage error
                     |
                     +-> tests/cli.rs observes status + stdout + stderr

canonical .ai policy -> harness generators -> root/client carriers
                                |
                                +-> tests/harness.rs rejects byte or inventory drift
```

The Rust product is intentionally one file. Extraction is justified only when implemented domain behavior creates an independently testable boundary.

## Repository patterns

- Public behavior tests execute the compiled binary; they do not assert parser fields.
- Just owns normal task orchestration; GitHub Actions invokes Just.
- Canonical policy is authored under `.ai/harness`; generated carriers are never edited directly.
- Rustfmt and Clippy own mechanical source style.
