set minimum-version := "1.55.0"
set default-list

cargo_home := env_var_or_default("CARGO_HOME", env_var("HOME") + "/.cargo")
export PATH := cargo_home + "/bin:" + env_var("PATH")

[doc("Prepare the pinned Rust toolchain and locked dependencies")]
setup: doctor
    cargo fetch --locked

[doc("Report the active developer toolchain and executable paths")]
doctor:
    @just --version
    @rustup --version
    @rustup show active-toolchain
    @command -v rustc
    @rustc --version
    @command -v cargo
    @cargo --version
    @rustfmt --version
    @cargo clippy --version

[doc("Format all Rust source files")]
fmt:
    cargo fmt --all

[doc("Check Rust formatting without changing source")]
fmt-check:
    cargo fmt --all -- --check

[doc("Lint all Rust targets and features; deny warnings")]
lint:
    cargo clippy --locked --all-targets --all-features -- -D warnings

[positional-arguments]
[doc("Run tests, optionally forwarding Cargo and test arguments")]
test *args:
    cargo test --locked "$@"

[doc("Type-check all Rust targets and features")]
check:
    cargo check --locked --all-targets --all-features

[doc("Build the Gloton debug binary")]
build:
    cargo build --locked

[positional-arguments]
[doc("Run Gloton with arguments")]
run *args:
    cargo run --locked -- "$@"

[doc("Install Gloton from this checkout")]
install:
    cargo install --locked --path .

[doc("Run the complete non-mutating repository gate")]
ci: fmt-check lint test build
