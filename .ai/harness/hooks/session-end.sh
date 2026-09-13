#!/usr/bin/env bash
# session-end.sh — Harness health check at session end (bookend pattern).
# Writes .ai/harness/health-report.md when gaps found, deletes when all pass.
# Called by Claude Code Stop hook / Cursor sessionEnd. Non-blocking (always exit 0).
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null || pwd)}}"
HARNESS_DIR="${PROJECT_DIR}/.ai/harness"
MEMORY_DIR="${PROJECT_DIR}/.ai/memory"
REPORT="${PROJECT_DIR}/.ai/harness/health-report.md"
LESSON_POLICY="${HARNESS_DIR}/hooks/lesson_memory.py"
FRESHNESS_RECEIPT="${MEMORY_DIR}/lesson-freshness-backfill.json"
run_lesson_policy() {
  command -v perl >/dev/null 2>&1 || return 127
  perl -e 'alarm 5; exec @ARGV' -- python3 "$LESSON_POLICY" "$@"
}


# Exit early if not a harnessed repo
[[ -d "$HARNESS_DIR" ]] || exit 0

gaps=()
required_governance_rules=(
  memory-freshness.md
  rules-codebase-sync.md
  ddd-freshness.md
  root-files-freshness.md
  specs-driven.md
  anchor-context-startup.md
  harness-self-improvement.md
  anti-slop-gate.md
  change-impact-review.md
  adversarial-dispatch-discipline.md
  actionable-artifact-gate.md
)

# ── DDD Project Intelligence ────────────────────────────────────────
ddd_project="$HARNESS_DIR/ddd-project.md"
if [[ ! -s "$ddd_project" ]]; then
  gaps+=("ACTION: Populate .ai/harness/ddd-project.md — project identity is empty")
elif [[ $(/usr/bin/wc -l < "$ddd_project") -lt 10 ]]; then
  gaps+=("ACTION: Expand .ai/harness/ddd-project.md — too short (<10 lines), likely a stub")
elif grep -q '{{' "$ddd_project" 2>/dev/null; then
  gaps+=("ACTION: Fill placeholders in .ai/harness/ddd-project.md — contains unfilled {{ templates")
fi

# ── DDD Ubiquitous Language ─────────────────────────────────────────
ddd_lang="$HARNESS_DIR/ddd-ubiquitous-language.md"
if [[ ! -s "$ddd_lang" ]]; then
  gaps+=("ACTION: Populate .ai/harness/ddd-ubiquitous-language.md — domain vocabulary is empty")
elif [[ $(/usr/bin/wc -l < "$ddd_lang") -lt 10 ]]; then
  gaps+=("ACTION: Expand .ai/harness/ddd-ubiquitous-language.md — too short (<10 lines), likely a stub")
elif grep -q '{{' "$ddd_lang" 2>/dev/null; then
  gaps+=("ACTION: Fill placeholders in .ai/harness/ddd-ubiquitous-language.md — contains unfilled {{ templates")
fi

# ── Lessons Learned ─────────────────────────────────────────────────
ll_file="$MEMORY_DIR/lessons-learned.json"
if [[ ! -f "$ll_file" ]]; then
  gaps+=("ACTION: Create .ai/memory/lessons-learned.json — no persistent memory file")
elif [[ ! -s "$ll_file" ]]; then
  gaps+=("ACTION: Add entries to .ai/memory/lessons-learned.json — currently empty")
fi
if [[ -f "$ll_file" ]]; then
  if [[ ! -s "$LESSON_POLICY" ]]; then
    gaps+=("ACTION: Restore .ai/harness/hooks/lesson_memory.py — freshness policy is missing")
  elif ! command -v python3 >/dev/null 2>&1; then
    gaps+=("ACTION: Install python3 — lesson freshness policy cannot run")
  elif ! command -v perl >/dev/null 2>&1; then
    gaps+=("ACTION: Install perl — bounded lesson freshness execution is unavailable")
  elif freshness_status="$(run_lesson_policy freshness \
    --lessons "$ll_file" \
    --receipt "$FRESHNESS_RECEIPT" \
    --format summary 2>&1)"; then
    case "$freshness_status" in
      *"LESSON_FRESHNESS:SUMMARY:total=0:"*)
        gaps+=("ACTION: Add entries to .ai/memory/lessons-learned.json — policy reports zero entries")
        ;;
    esac
    case "$freshness_status" in
      *"LESSON_FRESHNESS:ENFORCEMENT:inert:"*)
        freshness_reason="${freshness_status#*LESSON_FRESHNESS:ENFORCEMENT:inert:}"
        freshness_reason="${freshness_reason%%$'\n'*}"
        gaps+=("ACTION: Run codebase-harness-reflect freshness backfill on an authorized corpus copy, then publish .ai/memory/lesson-freshness-backfill.json — ${freshness_reason}")
        ;;
    esac
  else
    gaps+=("ACTION: Repair .ai/harness/hooks/lesson_memory.py — freshness status failed")
  fi
fi

# ── Task-Local Lessons Awaiting Consolidation ───────────────────────
pending_task_lesson=""
if [[ -d "$PROJECT_DIR/.ai/tasks" ]]; then
  pending_task_lesson="$(find "$PROJECT_DIR/.ai/tasks" -path '*/lessons-learned/*.md' -type f -size +0c -print -quit 2>/dev/null || true)"
  if [[ -n "$pending_task_lesson" ]]; then
    gaps+=("ACTION: Run codebase-harness-reflect or 2ndbrain-memory-consolidate — task-local lesson not yet consolidated: ${pending_task_lesson#"$PROJECT_DIR"/}")
  fi
fi

# ── Governance Rules ────────────────────────────────────────────────
for rule in "${required_governance_rules[@]}"; do
  if [[ ! -f "$HARNESS_DIR/rules/governance/$rule" ]]; then
    gaps+=("ACTION: Create .ai/harness/rules/governance/$rule — mandatory governance rule missing")
  fi
done

# ── Root Files ──────────────────────────────────────────────────────
for root in AGENTS.md CLAUDE.md; do
  if [[ ! -s "$PROJECT_DIR/$root" ]]; then
    gaps+=("ACTION: Create $root — root context file missing or empty")
  fi
done

# ── Write or Delete Report ──────────────────────────────────────────
if [[ ${#gaps[@]} -gt 0 ]]; then
  {
    printf '# Harness Health Report\n\n'
    printf '> Auto-generated by session-end health check. Fix these issues, then the next session-end check will clear this file.\n\n'
    printf '**%d improvement(s) needed:**\n\n' "${#gaps[@]}"
    n=1
    for gap in "${gaps[@]}"; do
      printf '%d. %s\n' "$n" "$gap"
      ((n++))
    done
    printf '\n---\nGenerated: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$REPORT"
else
  rm -f "$REPORT"
fi

# ── Consolidation Attestation (Second Brain NN-6 Memory Gate) ───────
# Writes a baseline attestation so the parent Claude Code Stop hook does NOT block
# session end. The agent's 2ndbrain-memory-consolidate skill may OVERWRITE this
# file with a real attestation (status: durable_learnings_written) during Phase 7/8.
# Schema: {"status","reason","agent","session_id","timestamp","findings_count"}
ATTESTATION="${PROJECT_DIR}/.ai/runtime/second-brain/consolidation-attestation.json"
mkdir -p "$(dirname "$ATTESTATION")"
if [[ ! -f "$ATTESTATION" ]]; then
  SECOND_BRAIN_ROOT="${SECOND_BRAIN_PATH:-${SECOND_BRAIN_VAULT_LOCAL:-}}"
  if [[ -n "$pending_task_lesson" ]]; then
    status="durable_learnings_pending"
    reason="Task-local lessons exist under .ai/tasks and need codebase-harness-reflect or 2ndbrain-memory-consolidate"
  elif [[ -z "$SECOND_BRAIN_ROOT" ]]; then
    status="memory_system_unavailable"
    reason="SECOND_BRAIN_PATH and SECOND_BRAIN_VAULT_LOCAL not set in this environment"
  elif [[ ! -s "${SECOND_BRAIN_ROOT}/llm-wiki/_index.md" ]]; then
    status="memory_system_unavailable"
    reason="Second Brain root set but llm-wiki/_index.md missing"
  else
    status="no_durable_learnings"
    reason="Session-end health check ran; agent did not invoke 2ndbrain-memory-consolidate"
  fi
  printf '{"status":"%s","reason":"%s","agent":"scaffolded-session-end-hook","session_id":"%s","timestamp":"%s","findings_count":%d}\n' \
    "$status" "$reason" "${CLAUDE_CODE_SESSION_ID:-${CLAUDE_SESSION_ID:-unknown}}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${#gaps[@]}" \
    > "$ATTESTATION"
fi

exit 0