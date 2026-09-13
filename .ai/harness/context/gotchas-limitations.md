# Gotchas and limitations

- A Homebrew `rustc`/`cargo` may precede rustup proxies in the ambient PATH. The Justfile prepends Cargo home; use `just doctor` to inspect the effective tools.
- Version 0.1.0 does not discover, compare, clone, pull, or synchronize repositories. README prose and help must remain explicit about that boundary.
- Generated root/client policy carriers are derived bytes. Edit canonical `.ai/harness` sources and regenerate.
- Cursor and Antigravity rule arrival is Tier C until those clients expose a repository-local effective-load receipt. File parity alone is not runtime proof.
