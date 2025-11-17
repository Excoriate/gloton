---
description: "Enforce tracing span instrumentation using #[instrument] macro, manual span creation, span relationships, and event recording within execution contexts"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - "rust-logging-patterns.md"
  - "rust-observability-integration.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Tracing Instrumentation

## Cohesion Principle

This rule focuses exclusively on **tracing span instrumentation** - the mechanisms for tracking execution contexts and operation boundaries. It governs:

- **#[instrument] macro usage** (automatic span creation for functions)
- **Manual span creation** (info_span!, debug_span! for explicit contexts)
- **Span relationships** (parent-child hierarchies, span following)
- **Event recording within spans** (attaching events to execution contexts)

These aspects belong together because they define WHERE and HOW spans wrap execution contexts, independent of WHAT events are logged within those contexts (rust-logging-patterns.md) or WHAT external telemetry systems consume the span data (rust-observability-integration.md). Separating span instrumentation from logging patterns prevents conflating execution tracking (this rule) with event creation (logging), while isolating observability infrastructure (integration) maintains architectural boundaries.

**Split from:** `rust-observability-logging.md` - extracted span instrumentation while logging patterns and observability integration moved to dedicated rules.

## Description

Enforce tracing span instrumentation using `#[instrument]` macro and manual span creation to track execution contexts, operation boundaries, and causal relationships. This rule ensures distributed tracing captures meaningful execution flows for debugging and performance analysis.

## Rule

1. **Use #[instrument] for function tracing**
   - Apply `#[instrument]` to public API functions, async functions, and significant operations
   - Specify log level: `#[instrument(level = Level::INFO)]` (default: DEBUG)
   - Skip arguments with sensitive data: `#[instrument(skip(password))]`
   - Skip large or non-Debug arguments: `#[instrument(skip(data))]`
   - **Rationale**: Automatic span creation reduces boilerplate and ensures consistent tracing

2. **Create manual spans for significant operations**
   - Use `tracing::info_span!("operation_name")` for important boundaries
   - Enter spans with `let _guard = span.enter()` for RAII-based tracking
   - Add contextual fields: `info_span!("process", user_id = %id, size = data.len())`
   - Prefer manual spans for granular control within complex functions

3. **Establish span relationships**
   - Child spans inherit parent context automatically (tracing runtime handles propagation)
   - Use `Span::current()` to reference active span
   - Record events within spans: `tracing::info!(parent: &span, "Event message")`
   - Follow spans across async boundaries with `.instrument()` or `.with_subscriber()`

4. **Record events within span contexts**
   - Events inherit span fields automatically
   - Add span-specific events: `info!("Checkpoint reached")`
   - Use `span.record()` to add fields dynamically: `span.record("result", &result_size)`
   - Avoid creating spans without events (empty spans add overhead)

## Implementation

Cursor IDE enforcement:

- **Detection**: Identify public functions without `#[instrument]` macro
- **Suggestion**: Recommend `#[instrument]` with appropriate level and skip parameters
- **Validation**: Check for manual span creation in complex operations (loops, branching logic)
- **Relationship check**: Verify events occur within span contexts (not orphaned)
- **Performance**: Flag excessive span creation (spans without events, nano-spans)

## Benefits

- **Distributed tracing**: Spans enable end-to-end request flow visualization across services
- **Performance profiling**: Span duration reveals bottlenecks and optimization opportunities
- **Causal debugging**: Span hierarchies show execution paths leading to errors
- **Async context tracking**: Spans propagate across async boundaries for coherent traces
- **Low overhead**: Zero-cost abstractions when tracing is disabled

## Examples

### ✅ CORRECT: Comprehensive span instrumentation

```rust
use tracing::{info, error, instrument, info_span, Level};

/// Service with #[instrument] on public functions
#[derive(Debug)]
pub struct DataService {
    name: String,
}

impl DataService {
    /// Constructor with instrumentation
    #[instrument(level = Level::DEBUG)]
    pub fn new(name: String) -> Self {
        info!(name = %name, "Creating new DataService");
        Self { name }
    }

    /// Process request with automatic span
    #[instrument(level = Level::INFO, skip(self, data))]
    pub async fn process_request(
        &self,
        request_id: &str,
        data: &[u8],
    ) -> Result<ProcessedData, Error> {
        info!(
            request_id = %request_id,
            data_size = data.len(),
            "Starting request processing"
        );

        // Manual span for sub-operation
        let validation_span = info_span!(
            "validate_data",
            request_id = %request_id,
            data_size = data.len()
        );
        let _guard = validation_span.enter();

        info!("Validating data format");
        let valid = validate(data).await?;

        // Record dynamic field
        validation_span.record("is_valid", &valid);

        drop(_guard);  // Exit validation span

        // Another manual span for processing
        let process_span = info_span!(
            "transform_data",
            request_id = %request_id
        );
        let _guard = process_span.enter();

        match transform(data).await {
            Ok(result) => {
                info!(result_size = result.len(), "Transformation complete");
                Ok(result)
            }
            Err(e) => {
                error!(error = %e, "Transformation failed");
                Err(e)
            }
        }
    }

    /// Helper function with instrumentation
    #[instrument(level = Level::DEBUG, skip(self))]
    async fn validate(&self, data: &[u8]) -> Result<bool, Error> {
        info!(data_size = data.len(), "Validating data");
        // Validation logic...
        Ok(true)
    }
}

/// Async function with span propagation
#[instrument(level = Level::INFO)]
pub async fn orchestrate_workflow(workflow_id: &str) -> Result<(), Error> {
    info!(workflow_id = %workflow_id, "Starting workflow orchestration");

    // Create span for parallel operations
    let parallel_span = info_span!("parallel_tasks", workflow_id = %workflow_id);

    // Spawn tasks with span propagation
    let task1 = tokio::spawn(
        async move {
            info!("Task 1 executing");
            // Task 1 logic
        }.instrument(parallel_span.clone())  // Propagate span to async task
    );

    let task2 = tokio::spawn(
        async move {
            info!("Task 2 executing");
            // Task 2 logic
        }.instrument(parallel_span)  // Propagate span to async task
    );

    // Await tasks
    task1.await??;
    task2.await??;

    info!(workflow_id = %workflow_id, "Workflow orchestration complete");
    Ok(())
}
```

### ❌ INCORRECT: Missing or improper span instrumentation

```rust
use tracing::{info, error};

/// Service without instrumentation
pub struct DataService {
    name: String,
}

impl DataService {
    /// ❌ Public constructor without #[instrument]
    pub fn new(name: String) -> Self {
        // ❌ No span context
        println!("Creating service: {}", name);
        Self { name }
    }

    /// ❌ Async function without instrumentation
    pub async fn process_request(
        &self,
        request_id: &str,
        data: &[u8],
    ) -> Result<ProcessedData, Error> {
        // ❌ No span created for significant operation
        info!("Processing request");

        // ❌ No span for sub-operation
        let valid = validate(data).await?;

        // ❌ Events without span context
        match transform(data).await {
            Ok(result) => {
                info!("Transformation complete");
                Ok(result)
            }
            Err(e) => {
                error!("Transformation failed: {}", e);
                Err(e)
            }
        }
    }

    /// ❌ Helper without instrumentation
    async fn validate(&self, data: &[u8]) -> Result<bool, Error> {
        // ❌ No span, no context
        println!("Validating data");
        Ok(true)
    }
}

/// ❌ Async function without span propagation
pub async fn orchestrate_workflow(workflow_id: &str) -> Result<(), Error> {
    // ❌ No #[instrument] macro
    info!("Starting workflow");

    // ❌ Spawned tasks lose span context
    let task1 = tokio::spawn(async move {
        // ❌ No span propagation - orphaned context
        info!("Task 1 executing");
    });

    let task2 = tokio::spawn(async move {
        // ❌ No span propagation - orphaned context
        info!("Task 2 executing");
    });

    task1.await??;
    task2.await??;

    Ok(())
}
```

**Why incorrect patterns fail:**

- Missing `#[instrument]` on public functions loses execution context in distributed traces
- No manual spans for sub-operations creates flat, uninformative trace hierarchies
- Events without spans are orphaned (can't be correlated with requests/operations)
- Async tasks without `.instrument()` lose parent context, breaking causality
- No span relationships prevent understanding call graphs and bottleneck analysis

## Related Rules

- **rust-logging-patterns.md** - Structured logging within spans (defines WHAT events are recorded in span contexts)
- **rust-observability-integration.md** - Span export and distributed tracing integration (defines HOW spans reach external systems)
