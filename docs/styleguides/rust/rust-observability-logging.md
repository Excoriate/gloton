---
title: "Rust Observability and Logging Best Practices"
description: "DEPRECATED: Split into rust-logging-patterns.md, rust-tracing-instrumentation.md, and rust-observability-integration.md for better cohesion and maintainability"
globs: ["**/*.rs"]
alwaysApply: false
deprecated: true
replacement_rules:
  - "rust-logging-patterns.md"
  - "rust-tracing-instrumentation.md"
  - "rust-observability-integration.md"
---

## ⚠️ DEPRECATION NOTICE

**This rule has been deprecated as of 2025-01-30.**

**Reason:** Monolithic observability rule combined disparate concerns (logging patterns, span instrumentation, metrics integration) reducing cohesion and maintainability.

**Migration Path:**

- For **structured logging** (tracing macros, log levels, structured fields) → Use `rust-logging-patterns.md`
- For **span instrumentation** (#[instrument], span creation, span relationships) → Use `rust-tracing-instrumentation.md`
- For **observability integration** (metrics, error tracking, distributed tracing export) → Use `rust-observability-integration.md`

**Content below preserved for historical reference only.**

---

## Description

This rule enforces best practices for logging, tracing, and metrics in Rust applications.

## Rule

- **Pattern**: `*.rs`
- **Severity**: Warning
- **Category**: Observability

## Checks

1. **Structured Logging**
   - Use `tracing` instead of `log`
   - Include contextual information
   - Use appropriate log levels
   - Add structured fields to events

2. **Span Usage**
   - Create spans for significant operations
   - Use `#[instrument]` for function tracing
   - Record important events within spans
   - Use span relationships appropriately

3. **Metrics Collection**
   - Use `metrics` crate for metrics
   - Record meaningful metrics
   - Use appropriate metric types
   - Include relevant labels

4. **Error Tracking**
   - Record errors with context
   - Use error spans for debugging
   - Include error details in events
   - Track error frequencies

## Examples

### Good

```rust
use tracing::{info, error, instrument, Level};
use metrics::{counter, gauge};

#[instrument(level = Level::INFO, skip(input))]
pub async fn process_data(input: &[u8]) -> Result<(), Error> {
    // Record metric for input size
    gauge!("data.input.size", input.len() as f64);

    // Create a span for the processing operation
    let span = tracing::info_span!("processing_data");
    let _guard = span.enter();

    // Record structured event
    info!(
        input_size = input.len(),
        "Starting data processing"
    );

    match process(input).await {
        Ok(result) => {
            // Record success metric
            counter!("data.process.success", 1);
            info!(
                result_size = result.len(),
                "Data processing completed"
            );
            Ok(())
        }
        Err(e) => {
            // Record error metric
            counter!("data.process.error", 1);
            error!(
                error = %e,
                error_type = std::any::type_name_of_val(&e),
                "Data processing failed"
            );
            Err(e)
        }
    }
}

/// A service that uses tracing for observability
#[derive(Debug)]
pub struct Service {
    name: String,
}

impl Service {
    #[instrument(level = Level::DEBUG)]
    pub fn new(name: String) -> Self {
        info!(name = %name, "Creating new service");
        Self { name }
    }

    #[instrument(level = Level::INFO, skip(self))]
    pub async fn handle_request(&self, request: Request) -> Result<Response, Error> {
        // Record request metric
        counter!("service.requests", 1, "service" => self.name.clone());

        let span = tracing::info_span!(
            "handle_request",
            service = %self.name,
            request_id = %request.id
        );

        let _guard = span.enter();

        info!(
            method = %request.method,
            path = %request.path,
            "Processing request"
        );

        // Implementation
    }
}
```

### Bad

```rust
// Bad: Using println! instead of structured logging
fn process_data(data: &[u8]) {
    println!("Processing data of size {}", data.len());
}

// Bad: Missing context in error logging
fn handle_error(e: Error) {
    error!("Error occurred: {}", e);
}

// Bad: Not using spans for operation tracking
async fn process_request(req: Request) -> Result<Response, Error> {
    // No span tracking
    let result = process(req).await;
    // No metrics
    result
}
```

## Implementation

Cursor IDE and linters should enforce these practices through:

- Detection of `println!` usage instead of structured logging
- Validation of tracing span creation for significant operations
- Checking for metric recording at key points
- Analysis of error logging completeness and context
- Verification of `#[instrument]` macro usage on public functions

## Benefits

Proper observability practices ensure:

- **Effective debugging and troubleshooting**: Structured logs provide rich context for investigation
- **Performance monitoring**: Metrics and spans enable proactive performance optimization
- **Error tracking and analysis**: Comprehensive error logging reveals failure patterns
- **System health monitoring**: Real-time metrics surface operational issues quickly
- **Production insights**: Distributed tracing reveals behavior in complex distributed systems

## References

- [tracing Documentation](https://docs.rs/tracing/latest/tracing)
- [metrics Documentation](https://docs.rs/metrics/latest/metrics)
- [OpenTelemetry Rust](https://opentelemetry.io/docs/instrumentation/rust)
