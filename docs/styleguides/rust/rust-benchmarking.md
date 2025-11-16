---
description: "Enforce rigorous benchmarking practices using Criterion for statistical analysis, regression detection, and quantitative performance validation in Rust code"
category: "rust"
version: "2.1.0"
status: "stable"
created: "2025-01-30"
updated: "2025-11-13"
authors: ["stdlib-team", "A. T."]
related:
  - "./rust-profiling-analysis.md"
  - "./rust-optimization-techniques.md"
  - "./rust-memory-optimization.md"
deprecated: false
globs: ["**/*.rs", "**/benches/*.rs"]
alwaysApply: true
---

# Rust Benchmarking Best Practices with Criterion

## Cohesion Principle

**WHY These Aspects Belong Together:**

Benchmarking forms a unified performance validation methodology where Criterion setup, statistical analysis, and regression detection work synergistically to produce reliable performance measurements. Criterion provides microbenchmarking infrastructure with outlier detection, statistical significance testing, and HTML report generation—these capabilities are interdependent. Statistical analysis (confidence intervals, variance estimation) quantifies measurement uncertainty, enabling evidence-based optimization decisions rather than anecdotal "feels faster" claims. Regression detection compares current benchmarks against baseline measurements to automatically identify performance degradations before they reach production. Separating these concepts would fragment the validation process; running benchmarks without statistical analysis produces unreliable results (noise vs. signal), while detecting regressions without proper Criterion setup lacks the baseline data needed for comparison. Together, they form a complete performance validation pipeline: measure with statistical rigor → validate against baselines → detect regressions automatically.

---

## Description

Criterion is Rust's industry-standard benchmarking library, providing statistical analysis, outlier detection, and automated regression detection for performance validation. This rule enforces systematic benchmarking practices: proper Criterion configuration, statistical interpretation of benchmark results, and continuous performance regression detection in CI/CD pipelines to ensure optimizations produce measurable, reproducible improvements.

---

## Rule

### 1. Use Criterion for All Microbenchmarks

**MANDATORY**: Use Criterion (not the unstable, nightly-only built-in `#[bench]`) for all performance benchmarks requiring statistical rigor.

**Criterion Setup:**
```toml
# Cargo.toml
[dev-dependencies]
criterion = { version = "0.5", features = ["html_reports"] }

[[bench]]
name = "my_benchmark"
harness = false  # Disable default benchmark harness to use Criterion's
```

**Basic Benchmark Structure:**
```rust
// benches/my_benchmark.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_function(c: &mut Criterion) {
    c.bench_function("my_function_name", |b| {
        b.iter(|| {
            // The code to be benchmarked
            my_function(black_box(42))
        });
    });
}

criterion_group!(benches, benchmark_function);
criterion_main!(benches);
```

**Why Criterion Over `#[bench]`:**
- **Statistical Analysis**: Provides mean, standard deviation, and confidence intervals.
- **Outlier Detection**: Filters measurement noise for more accurate results.
- **HTML Reports**: Generates detailed visual reports with plots and trend lines.
- **Regression Detection**: Automatically detects performance degradations against a baseline.
- **Stable API**: Works on stable Rust, whereas `#[bench]` requires a nightly compiler.

**Detection**: Projects using `#[bench]` instead of Criterion for statistical benchmarks.

### 2. Always Use `black_box()` to Prevent Compiler Optimizations

**MANDATORY**: Wrap benchmark inputs and outputs in `criterion::black_box()` to prevent the compiler from optimizing away the code being measured.

**Black Box Pattern:**
```rust
use criterion::black_box;

c.bench_function("compute", |b| {
    let input = vec![1, 2, 3, 4, 5];

    b.iter(|| {
        // black_box() prevents the compiler from:
        // 1. Constant-folding the input.
        // 2. Performing dead code elimination if the result is unused.
        let result = compute(black_box(&input));
        black_box(result); // Prevent DCE of the result
    });
});
```

**Why `black_box` is Critical:**
The Rust compiler is highly aggressive in its optimizations. If it can determine that the result of a computation is unused or that the input is constant, it may eliminate the entire code block, leading to benchmarks that measure nothing.

**Detection**: Benchmarks that do not use `black_box()` for either their inputs or outputs.

### 3. Configure Appropriate Sample Sizes and Measurement Time

**MANDATORY**: Adjust Criterion's sample size and measurement time to suit the characteristics of the code being benchmarked.

**Configuration Options:**
```rust
use criterion::{Criterion, BenchmarkId, PlotConfiguration, AxisScale};
use std::time::Duration;

fn configure_benchmark(c: &mut Criterion) {
    // Default: 100 samples, 5 seconds measurement time. Good for most cases.
    c.bench_function("default_benchmark", |b| b.iter(|| expensive_operation()));

    // For very fast operations, increase the sample size for statistical significance.
    let mut group = c.benchmark_group("fast_operations");
    group.sample_size(1000);
    group.measurement_time(Duration::from_secs(10));
    group.bench_function("fast_op", |b| b.iter(|| fast_operation()));
    group.finish();

    // For very slow operations, reduce the sample size to keep benchmark runtime reasonable.
    let mut group = c.benchmark_group("slow_operations");
    group.sample_size(10);
    group.measurement_time(Duration::from_secs(15));
    group.bench_function("slow_op", |b| b.iter(|| slow_operation()));
    group.finish();
}
```

**Sample Size Guidelines:**
- **Fast operations (<1µs)**: 1000+ samples.
- **Medium operations (1µs-1ms)**: 100 samples (default).
- **Slow operations (>1ms)**: 10-50 samples.

**Detection**: Benchmarks with sample sizes that are inappropriate for the operation's duration (e.g., fast ops with 10 samples).

### 4. Interpret Statistical Metrics Correctly

**MANDATORY**: Understand and document Criterion's statistical output, including the mean, standard deviation, and confidence intervals.

**Criterion Output Interpretation:**
```text
my_function             time:   [48.123 µs 48.456 µs 48.891 µs]
                        change: [-2.3421% -1.8234% -1.2456%] (p = 0.00 < 0.05)
                        Performance has improved.
```

- **Mean**: The average execution time.
- **Confidence Interval `[lower mean upper]`**: There is a 95% probability that the true mean lies within this range.
- **Change**: The performance difference compared to the baseline (saved in `target/criterion/`).
- **p-value**: The statistical significance of the change. A p-value less than 0.05 indicates a statistically significant change, not just random noise.

**Detection**: Reporting benchmark results without including statistical context (confidence intervals, p-values).

### 5. Use Parameterized Benchmarks for Input Size Scaling

**MANDATORY**: Benchmark functions with a range of input sizes to understand their algorithmic complexity and scaling behavior.

**Parameterized Benchmark Pattern:**
```rust
use criterion::{BenchmarkId, Criterion};

fn benchmark_scaling(c: &mut Criterion) {
    let mut group = c.benchmark_group("vector_sum");

    for size in [10, 100, 1_000, 10_000, 100_000].iter() {
        let input: Vec<i32> = (0..*size as i32).collect();

        group.bench_with_input(BenchmarkId::from_parameter(size), &input, |b, input| {
            b.iter(|| {
                black_box(vector_sum(black_box(input)));
            });
        });
    }
    group.finish();
}

fn vector_sum(input: &[i32]) -> i32 {
    input.iter().sum()
}
```
This generates plots showing how execution time scales with input size, helping to identify complexities like O(n), O(n log n), or O(n²).

**Detection**: Benchmarks of algorithms that operate on variable-sized inputs without parameterization.

### 6. Enable Regression Detection in CI/CD

**MANDATORY**: Integrate benchmark runs into your CI/CD pipeline to automatically detect performance regressions.

**CI Configuration (GitHub Actions):**
```yaml
# .github/workflows/benchmark.yml
name: Benchmark

on:
  push:
    branches: [main]
  pull_request:

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Run benchmarks and save baseline
        run: cargo bench -- --save-baseline current
      - name: Compare with main branch baseline
        run: |
          git fetch origin main:main
          git checkout main -- target/criterion
          cargo bench -- --baseline main
```

**Detection**: Performance-critical projects lacking CI integration for benchmarks.

### 7. Generate and Review HTML Reports

**MANDATORY**: Review Criterion's HTML reports to understand performance trends, variance, and outliers.

```bash
# Benchmarks automatically generate HTML reports in target/criterion/
cargo bench

# Open reports in your browser
open target/criterion/report/index.html
```

**Detection**: Interpreting benchmark results without reviewing the detailed HTML reports.

---

## Implementation

Cursor IDE and CI tools should enforce these practices by:
- **Validating Criterion Configuration**: Check `Cargo.toml` for `criterion` and `harness = false`.
- **Detecting Missing `black_box`**: Parse benchmark code to ensure inputs and outputs are wrapped.
- **Analyzing Statistical Output**: Parse Criterion's output to require documentation of statistical metrics.
- **Enforcing CI Integration**: Check for benchmark-related jobs in CI configuration files.

---

## Benefits

- **Statistical Rigor**: Eliminates measurement noise and provides confidence in results.
- **Reproducible Results**: Ensures stable measurements across different runs and environments.
- **Automated Regression Detection**: Catches performance degradations before they hit production.
- **Evidence-Based Optimization**: Replaces subjective "feels faster" claims with quantitative data.
- **Algorithmic Complexity Validation**: Empirically verifies how algorithms scale with input size.

---

## Examples

### ✅ CORRECT: Complete Criterion Benchmark with Statistical Analysis

```rust
// benches/my_app_bench.rs
use criterion::{black_box, criterion_group, criterion_main, BenchmarkId, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 1,
        1 => 1,
        n => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn benchmarks(c: &mut Criterion) {
    let mut group = c.benchmark_group("Fibonacci");
    for i in [20, 21].iter() {
        group.bench_with_input(BenchmarkId::new("Recursive", i), i, |b, i| {
            b.iter(|| fibonacci(black_box(*i)))
        });
    }
    group.finish();
}

criterion_group!(benches, benchmarks);
criterion_main!(benches);
```

### ❌ INCORRECT: Benchmark Without `black_box`

```rust
// This benchmark may report near-zero time because the compiler
// can optimize away the entire computation.
fn benchmark_bad(c: &mut Criterion) {
    c.bench_function("bad_benchmark", |b| {
        b.iter(|| {
            let result = 1 + 1;
        });
    });
}
```

---

## Related Rules

- **rust-profiling-analysis.md**: Use profiling to identify which parts of your code are performance-critical and thus worth benchmarking.
- **rust-optimization-techniques.md**: Apply optimization techniques and then use benchmarks to validate their impact.
- **rust-memory-optimization.md**: Benchmark memory allocation patterns to quantify the impact of memory optimizations.
