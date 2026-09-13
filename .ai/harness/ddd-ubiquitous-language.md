---
name: ddd-ubiquitous-language
description: Gloton repository-collection vocabulary and current implementation boundary.
type: ddd
alwaysApply: true
---
<!-- CONTINUOUSLY ENRICHED — update when domain terminology evolves -->

# Gloton ubiquitous language

| Term | Meaning now | Not interchangeable with |
|---|---|---|
| Gloton | The CLI product and `gloton` executable. | A synchronization service. |
| repository collection | A future user-selected set of local repositories and hosting records. | A Cargo workspace. |
| repository discovery | Planned observation of repository locations or host records. | An implemented command. |
| synchronization | Planned comparison or explicitly selected update behavior. | Automatic mutation, implemented behavior, or the current parser. |
| command boundary | The Clap-owned process grammar, help, version, status, stdout, and stderr. | Provider or domain behavior. |
| canonical policy | The single agent-facing source under `.ai/harness/`. | A generated root/client carrier. |
| carrier | A generated agent-client projection whose payload is copied from canonical policy. | An independently editable rule. |

No bounded repository-provider context or domain event exists in version 0.1.0. Introduce one only with implemented code, a named owner, and an observable consumer contract.

Last updated 2026-09-13.
