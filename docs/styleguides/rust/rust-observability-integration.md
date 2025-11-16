---
description: "Enforce observability integration with metrics collection, error tracking, distributed tracing export, and telemetry subscriber configuration"
category: "rust"
version: "2.0.0"
status: "stable"
created: "2025-01-30"
updated: "2025-01-30"
authors: ["stdlib-team"]
related:
  - "rust-logging-patterns.md"
  - "rust-tracing-instrumentation.md"
deprecated: false
globs: ["**/*.rs"]
alwaysApply: true
---

# Rust Observability Integration

## Cohesion Principle

This rule focuses exclusively on **observability system integration** - the mechanisms for exporting telemetry data to external monitoring systems. It governs:

- **Metrics collection** (counters, gauges, histograms via metrics crate)
- **Error tracking** (error frequency, error context, error metrics)
- **Distributed tracing export** (OpenTelemetry, Jaeger, Zipkin integration)
- **Telemetry subscriber configuration** (tracing-subscriber setup, filtering, formatting)

These aspects belong together because they define HOW observability data reaches external systems (Prometheus, Datadog, Jaeger), independent of HOW events are logged (rust-logging-patterns.md) or WHERE spans are created (rust-tracing-instrumentation.md). Separating observability integration from logging patterns prevents conflating telemetry export (this rule) with event creation (logging), while isolating span instrumentation (tracing) maintains focused responsibilities for execution tracking vs. data export.

**Split from:** `rust-observability-logging.md` - extracted observability integration while logging patterns and span instrumentation moved to dedicated rules.

## Description

Enforce observability integration with external monitoring systems through metrics collection (`metrics` crate), error tracking with contextual metrics, distributed tracing export (OpenTelemetry), and tracing subscriber configuration. This rule ensures production systems expose actionable telemetry for monitoring, alerting, and debugging.

## Rule

1. **Use `metrics` crate for quantitative monitoring**
   - **Counters** for cumulative values: `counter!("requests.total", 1)`
   - **Gauges** for point-in-time values: `gauge!("queue.size", queue.len() as f64)`
   - **Histograms** for distributions: `histogram!("request.duration", elapsed.as_secs_f64())`
   - Include labels for dimensions: `counter!("requests", 1, "status" => "success")`

2. **Track errors with metrics and context**
   - Record error frequencies: `counter!("errors.total", 1, "error_type" => error_name)`
   - Log errors with rich context: `error = %e, error_type = std::any::type_name_of_val(&e)`
   - Track error rates by operation/endpoint
   - Use histograms for error latencies: `histogram!("error.latency", elapsed.as_secs_f64())`

3. **Configure distributed tracing export**
   - Use OpenTelemetry for vendor-neutral tracing
   - Configure exporter (Jaeger, Zipkin, OTLP): `opentelemetry_jaeger::new_agent_pipeline()`
   - Set service name and resource attributes
   - Enable trace sampling for production (avoid 100% sampling)

4. **Configure tracing subscriber for telemetry**
   - Initialize subscriber with `tracing_subscriber::fmt()` or OpenTelemetry layer
   - Set log level filtering: `EnvFilter::new("info,my_crate=debug")`
   - Format for structured output (JSON for production, human-readable for dev)
   - Register global default: `tracing::subscriber::set_global_default(subscriber)`

## Implementation

Cursor IDE enforcement:
- **Detection**: Identify operations without metrics (request handling, data processing)
- **Suggestion**: Recommend appropriate metric type (counter for events, gauge for state, histogram for durations)
- **Validation**: Check for error tracking metrics in error handling code
- **Configuration check**: Verify subscriber initialization in main/entry point
- **Export check**: Ensure OpenTelemetry or equivalent exporter configured for distributed tracing

## Benefits

- **Production monitoring**: Metrics enable real-time dashboards, alerting, and capacity planning
- **Error visibility**: Error tracking reveals failure patterns and impact (frequency, affected users)
- **Distributed tracing**: End-to-end request flows across microservices for debugging
- **Performance analysis**: Histograms and span durations identify bottlenecks
- **Vendor flexibility**: OpenTelemetry enables switching monitoring backends without code changes

## Examples

### ✅ CORRECT: Comprehensive observability integration

```rust
use tracing::{info, error, instrument, Level};
use metrics::{counter, gauge, histogram};
use opentelemetry::sdk::trace as sdktrace;
use opentelemetry::global;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

/// Initialize observability with metrics and tracing
pub fn init_observability() -> Result<(), Box<dyn std::error::Error>> {
    // Configure OpenTelemetry exporter (Jaeger example)
    let tracer = opentelemetry_jaeger::new_agent_pipeline()
        .with_service_name("my-service")
        .with_max_packet_size(65_000)
        .install_simple()?;

    // Create tracing subscriber with OpenTelemetry layer
    let telemetry = tracing_opentelemetry::layer().with_tracer(tracer);

    // Configure log filtering
    let env_filter = tracing_subscriber::EnvFilter::try_from_default_env()
        .or_else(|_| tracing_subscriber::EnvFilter::try_new("info"))
        .unwrap();

    // Initialize subscriber with formatting and telemetry
    tracing_subscriber::registry()
        .with(env_filter)
        .with(tracing_subscriber::fmt::layer())
        .with(telemetry)
        .init();

    info!("Observability initialized with OpenTelemetry");
    Ok(())
}

/// Service with metrics and error tracking
pub struct ApiService {
    name: String,
}

impl ApiService {
    #[instrument(level = Level::INFO, skip(self))]
    pub async fn handle_request(&self, request: Request) -> Result<Response, Error> {
        // Record request metric with labels
        counter!(
            "api.requests.total",
            1,
            "service" => self.name.clone(),
            "method" => request.method.to_string()
        );

        // Track request duration
        let start = std::time::Instant::now();

        // Gauge for active requests (increment on entry, decrement on exit)
        gauge!("api.requests.active", 1.0);
        let _guard = scopeguard::guard((), |_| {
            gauge!("api.requests.active", -1.0);
        });

        info!(
            method = %request.method,
            path = %request.path,
            "Processing API request"
        );

        // Process request
        let result = self.process(request).await;

        // Record duration histogram
        let elapsed = start.elapsed();
        histogram!(
            "api.request.duration.seconds",
            elapsed.as_secs_f64(),
            "service" => self.name.clone()
        );

        match result {
            Ok(response) => {
                // Success metric
                counter!(
                    "api.requests.success",
                    1,
                    "service" => self.name.clone()
                );
                info!(status = response.status, "Request completed successfully");
                Ok(response)
            }
            Err(e) => {
                // Error tracking with metrics
                let error_type = std::any::type_name_of_val(&e);
                counter!(
                    "api.requests.error",
                    1,
                    "service" => self.name.clone(),
                    "error_type" => error_type
                );

                // Error latency histogram
                histogram!(
                    "api.error.duration.seconds",
                    elapsed.as_secs_f64(),
                    "error_type" => error_type
                );

                error!(
                    error = %e,
                    error_type = error_type,
                    "Request failed"
                );
                Err(e)
            }
        }
    }

    #[instrument(level = Level::DEBUG, skip(self))]
    async fn process(&self, request: Request) -> Result<Response, Error> {
        // Record processing-specific metrics
        gauge!("api.processing.queue.size", self.queue_size() as f64);

        // Processing logic...
        Ok(Response::ok())
    }

    fn queue_size(&self) -> usize {
        // Queue size implementation
        0
    }
}

/// Shutdown observability gracefully
pub fn shutdown_observability() {
    info!("Shutting down observability");
    global::shutdown_tracer_provider();
}
```

### ❌ INCORRECT: Missing observability integration

```rust
use tracing::{info, error};

/// ❌ No observability initialization
pub fn init() {
    // ❌ Only basic logging, no metrics or tracing export
    tracing_subscriber::fmt::init();
}

/// Service without metrics
pub struct ApiService {
    name: String,
}

impl ApiService {
    /// ❌ No metrics collection
    pub async fn handle_request(&self, request: Request) -> Result<Response, Error> {
        info!("Processing request");

        // ❌ No request counter
        // ❌ No duration tracking
        // ❌ No active request gauge

        let result = self.process(request).await;

        match result {
            Ok(response) => {
                // ❌ No success metric
                info!("Request completed");
                Ok(response)
            }
            Err(e) => {
                // ❌ No error metric
                // ❌ No error type tracking
                // ❌ No error latency histogram
                error!("Request failed: {}", e);
                Err(e)
            }
        }
    }

    async fn process(&self, request: Request) -> Result<Response, Error> {
        // ❌ No metrics for queue size or processing state
        Ok(Response::ok())
    }
}

/// ❌ No shutdown handling
// Traces may be lost on abrupt shutdown
```

**Why incorrect patterns fail:**
- No metrics prevent monitoring request rates, error rates, and system health
- Missing duration histograms hide performance degradation and bottlenecks
- No error tracking metrics obscure failure patterns and impact
- No OpenTelemetry export loses distributed tracing across services
- No graceful shutdown loses final traces and spans
- No gauge tracking (active requests, queue sizes) hides real-time state

## Related Rules

- **rust-logging-patterns.md** - Structured logging patterns (provides event data for observability)
- **rust-tracing-instrumentation.md** - Span instrumentation (provides execution context for distributed tracing)

## References

- [metrics Documentation](https://docs.rs/metrics/latest/metrics/)
- [OpenTelemetry Rust](https://opentelemetry.io/docs/instrumentation/rust/)
- [tracing-subscriber Documentation](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/)
- [tracing-opentelemetry Integration](https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/)
