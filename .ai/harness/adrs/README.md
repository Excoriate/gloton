# Architecture Decision Records

This directory is the repository's **append-only decision ledger**. Each file records one decision that was
made among ≥2 viable options with consequences expensive to reverse — what was chosen, what was rejected,
the mechanical failure the rejected option causes, and the accepted consequences.

This ledger is immutable by construction. It is the one durable store whose records must stay **frozen** —
editing a decided ADR to reverse it would falsify history rather than update understanding. Everything that
mutates as you learn (scars, directives, conventions, shapes) lives in the other harness stores, not here.

## How this ledger works

- **Filenames are `{NNNN}-{kebab-slug}.md`** — a 4-digit zero-padded id plus a kebab-case slug
  (e.g. `0001-event-sourced-orders.md`).
- **Ids are never reused and never renumbered.** Even if you delete an ADR file, its id is retired forever
  (the allocator remembers it via git history). A duplicate id prefix is a release blocker.
- **Superseded ADRs are KEPT, never deleted.** To reverse a decision, write a NEW ADR and mark the old one
  `status: superseded` with `superseded_by: NNNN`. The old record stays in the tree so future agents can
  see what was decided, why, and what replaced it.
- **`_adr-template.md` is the canonical bar.** Its non-numeric name keeps it out of the numbered ledger and
  out of id allocation.

## How to add an ADR

1. **Allocate the next safe id** — do NOT hand-pick a number:

   ```bash
   .ai/harness/adrs/adr-next-number.sh .ai/harness/adrs
   # → prints the next zero-padded id, e.g. 0007
   ```

2. **Copy the template** to `{NNNN}-{kebab-slug}.md` and fill it at the bar:

   ```bash
   cp .ai/harness/adrs/_adr-template.md .ai/harness/adrs/{NNNN}-{kebab-slug}.md
   ```

3. **Validate the anatomy floor** (a PASS means *well-formed*, not *good* — judge quality against the
   golden specimen):

   ```bash
   .ai/harness/adrs/validate-adr.sh .ai/harness/adrs/{NNNN}-{kebab-slug}.md
   ```

4. **To supersede** an existing decision: write a new ADR with `supersedes: NNNN`, then set the old ADR's
   `status: superseded` and `superseded_by: NNNN`. Never edit the old ADR's body to reverse it.

## How future agents should consult this ledger

Before doing **architecture, deployment, storage, security, module-boundary, API/wire-contract, IaC, or
CI/CD** work, **read the accepted ADRs here first.** They are binding context: a decision recorded here was
made deliberately, with the rejected alternatives and their mechanical failures named. Changing the
repository in a way that silently reverses an accepted ADR is a regression — if a recorded decision should
change, supersede it with a new ADR rather than quietly working around it.

An ADR with `status: accepted` is a constraint you honor. An ADR with `status: superseded` tells you what
was once true and what replaced it — read its `superseded_by` to find the current decision.
