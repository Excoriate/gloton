---
description: "Enforce structured logging patterns using tracing macros, appropriate log levels, contextual fields, and event composition in Rust applications"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - "rust-tracing-instrumentation.md"
  - "rust-observability-integration.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Logging Patterns

## Cohesion Principle

This rule focuses exclusively on **structured logging practices** - the foundational patterns for emitting log events with rich contextual information. It governs:

- **Log macro selection** (tracing vs log crate usage)
- **Log level appropriateness** (trace, debug, info, warn, error)
- **Structured field composition** (key-value pairs, typed fields)
- **Contextual information inclusion** (enriching events with diagnostic data)

These aspects belong together because they define HOW log events are created and enriched with context, independent of WHERE they occur (span instrumentation) or WHAT external systems consume them (observability integration). Separating logging patterns from tracing instrumentation prevents conflating event creation (this rule) with execution context tracking (rust-tracing-instrumentation.md), while isolating metrics and telemetry concerns (rust-observability-integration.md) maintains focused responsibilities.

**Split from:** `rust-observability-logging.md` - extracted logging-specific patterns while tracing instrumentation and observability integration moved to dedicated rules.

## Description

Enforce structured logging patterns using `tracing` macros with appropriate log levels, structured fields, and contextual information. This rule ensures log events provide rich diagnostic data for debugging and operational monitoring.

## Rule

1. **Use `tracing` over `log` crate**
   - Prefer `tracing::{trace, debug, info, warn, error}` macros
   - Avoid `log::{trace, debug, info, warn, error}` for new code
   - `tracing` provides superior structured logging and span integration
   - **Migration path**: For projects with dependencies that use the `log` crate, the `tracing-log` crate can be used to convert `log` records into `tracing` events.
   - Migration path: Replace `log::info!` with `tracing::info!`

2. **Apply appropriate log levels**
   - `trace!`: Extremely verbose diagnostic information (rarely used in production)
   - `debug!`: Detailed debugging information for development
   - `info!`: Informational messages about normal operations
   - `warn!`: Warning conditions that may require attention
   - `error!`: Error conditions requiring immediate attention
   - **Rationale**: Correct levels enable effective log filtering and alerting

3. **Use structured fields for contextual data**
   - Add key-value pairs: `info!(user_id = %id, "User logged in")`
   - Use display formatting: `%` for `Display`, `?` for `Debug`
   - Include relevant diagnostic context (IDs, sizes, durations)
   - Avoid string interpolation for structured data: `info!("Size: {}", size)` → `info!(size = size, "Processing data")`

4. **Compose rich log events**
   - Include actionable context (what, why, relevant state)
   - Add error details: `error = %e, error_type = std::any::type_name_of_val(&e)`
   - Record input/output characteristics: `input_size = data.len()`
   - Avoid redundant or obvious fields

## Implementation

Cursor IDE enforcement:

- **Detection**: Flag `println!`, `eprintln!`, or `log::*` macro usage
- **Suggestion**: Recommend `tracing::*` macros with structured fields
- **Validation**: Check for structured field usage (key-value pairs)
- **Level check**: Verify appropriate log level for context (error handling → `error!`, normal flow → `info!`)
- **Linting**: Use `clippy::print_stdout`, `clippy::print_stderr` for detection

## Benefits

- **Rich diagnostic context**: Structured fields enable powerful log queries and filtering
- **Consistent logging**: Standardized macros across codebase improve maintainability
- **Better debugging**: Contextual information accelerates root cause analysis
- **Log aggregation**: Structured logs integrate seamlessly with log management systems (Elasticsearch, Datadog, Splunk)
- **Performance**: Tracing's zero-cost abstractions minimize logging overhead

## Examples

### ✅ CORRECT: Structured logging with tracing

```rust
use tracing::{info, warn, error, debug};

/// Process user data with structured logging
pub async fn process_user_data(user_id: &str, data: &[u8]) -> Result<ProcessedData, Error> {
    // Info level with structured fields
    info!(
        user_id = %user_id,
        data_size = data.len(),
        "Starting user data processing"
    );

    // Validate data size
    if data.len() > MAX_SIZE {
        warn!(
            user_id = %user_id,
            data_size = data.len(),
            max_size = MAX_SIZE,
            "Data size exceeds maximum, truncating"
        );
    }

    // Process with debug logging
    debug!(user_id = %user_id, "Validating data format");

    match validate_and_process(data).await {
        Ok(result) => {
            info!(
                user_id = %user_id,
                result_size = result.len(),
                "User data processing completed successfully"
            );
            Ok(result)
        }
        Err(e) => {
            // Error with rich context
            error!(
                user_id = %user_id,
                error = %e,
                error_type = std::any::type_name_of_val(&e),
                data_size = data.len(),
                "User data processing failed"
            );
            Err(e)
        }
    }
}

/// HTTP request handler with contextual logging
pub async fn handle_request(request: &Request) -> Result<Response, Error> {
    info!(
        method = %request.method,
        path = %request.path,
        request_id = %request.id,
        "Incoming HTTP request"
    );

    // Debug level for detailed diagnostics
    debug!(
        request_id = %request.id,
        headers = ?request.headers,
        "Request headers received"
    );

    // Process request...
    Ok(Response::ok())
}
```

### ❌ INCORRECT: Unstructured logging or println

```rust
use log::{info, error};  // ❌ Using log crate instead of tracing

/// Poor logging practices
pub async fn process_user_data(user_id: &str, data: &[u8]) -> Result<ProcessedData, Error> {
    // ❌ Using println! instead of structured logging
    println!("Processing user data for {}", user_id);

    // ❌ String interpolation instead of structured fields
    info!("Data size: {}", data.len());

    // ❌ No contextual information
    println!("Starting validation");

    match validate_and_process(data).await {
        Ok(result) => {
            // ❌ Minimal context
            println!("Processing complete");
            Ok(result)
        }
        Err(e) => {
            // ❌ Generic error logging without context
            error!("Error occurred: {}", e);
            Err(e)
        }
    }
}

/// Poor request logging
pub async fn handle_request(request: &Request) -> Result<Response, Error> {
    // ❌ Using eprintln! for logging
    eprintln!("Request received: {} {}", request.method, request.path);

    // ❌ No structured fields or request ID
    info!("Processing request");

    Ok(Response::ok())
}
```

**Why incorrect patterns fail:**

- `println!` and `eprintln!` lack structure, filtering, and log level control
- `log` crate doesn't integrate with tracing spans and async contexts
- String interpolation (`{}`) prevents structured queries in log aggregation systems
- Missing contextual fields (IDs, sizes, types) hinder debugging
- Generic error messages without details slow incident response

## Related Rules

- **rust-tracing-instrumentation.md** - Span creation and #[instrument] usage (complements logging with execution context)
- **rust-observability-integration.md** - Metrics collection and telemetry export (extends logging with quantitative monitoring)
