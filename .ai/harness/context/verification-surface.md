---
schema: verification-surface/v1
generated_at: 2026-09-13T16:51:11Z
source_fingerprint: sha256:dbc54913a0596027d5d4e905009d4c96b2d39d9050b5ac89e3b9fd40dca6c05d
status: fresh
ci_relation: aligned-through-just-ci
---
# Verification Surface

Select every row matching the changed paths. Only `discriminating` evidence can close a behavioral claim; other states expose a check or a promotion blocker, not correctness.

| Match | State | Command | Pass proves | Does not prove | CI |
|---|---|---|---|---|---|
| `**/*` | `discriminating` | `./tests/verification-surface.sh` | the Gloton build, lint, format, behavior, and rule-projection gates passed through just ci and rejected a relevant duplicate-policy mutation | hosted CI success or runtime rule arrival in Cursor and Antigravity | `aligned-through-just-ci` |
