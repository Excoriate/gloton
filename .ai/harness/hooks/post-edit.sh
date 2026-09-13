#!/usr/bin/env bash
# post-edit.sh — Auto-format files on Edit/Write operations.
# Called by Claude Code PostToolUse, Cursor postToolUse.
# Non-blocking (always exit 0).
# HARNESS EXEMPTION: Skips structural .ai/ files (config, not code).
set -euo pipefail
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
if [ -z "$FILE" ]; then
  exit 0
fi
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-$(cd "$(dirname "$0")/../../.." && pwd)}}"
if [[ ! "${PROJECT_DIR}" = /* ]] || [[ ! -d "$PROJECT_DIR" ]]; then
  exit 0
fi
cd "$PROJECT_DIR"

# Skip harness files — they are configuration, not source code.
# This prevents unnecessary formatting and hook friction.
case "$FILE" in
  */.ai/harness/*|.ai/harness/*)                 exit 0 ;;
  */.ai/memory/*|.ai/memory/*)                   exit 0 ;;
  */.ai/runtime/*|.ai/runtime/*)                 exit 0 ;;
  */.ai/harness/context/*|.ai/harness/context/*) exit 0 ;;
esac

case "$FILE" in
  # Tailor cases from detected stack and formatters:
  # *.tf)  command -v just >/dev/null 2>&1 && just fmt 2>/dev/null || terraform fmt "$FILE" 2>/dev/null ;;
  # *.py)  command -v black >/dev/null 2>&1 && black --quiet "$FILE" 2>/dev/null ;;
  # *.ts|*.tsx|*.js|*.jsx)  command -v prettier >/dev/null 2>&1 && prettier --write "$FILE" 2>/dev/null ;;
  # *.go)  command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE" 2>/dev/null ;;
  # *.rs)  command -v rustfmt >/dev/null 2>&1 && rustfmt "$FILE" 2>/dev/null ;;
  # *.sh)  command -v shfmt >/dev/null 2>&1 && shfmt -w "$FILE" 2>/dev/null ;;
  *) ;;
esac
if [ -f .pre-commit-config.yaml ] && command -v pre-commit >/dev/null 2>&1; then
  pre-commit run --files "$FILE" 2>/dev/null || true
fi

# Change-impact advisory (opt-in, NON-BLOCKING): a product edit may stale a downstream surface
# (docs / toolchain config). The change-impact-review rule + session-end reflect are the primary
# gates; this is only a per-edit nudge. Enable with POST_EDIT_CHANGE_IMPACT_ADVISORY=1.
if [ "${POST_EDIT_CHANGE_IMPACT_ADVISORY:-0}" = "1" ] && [ -f .ai/harness/context/change-impact-map.md ]; then
  case "$FILE" in
    *.md|*.tf|*.py|*.ts|*.tsx|*.js|*.go|*.rs|*.sh|*.env*|*Dockerfile*|*.yaml|*.yml|*.toml|*.json)
      echo "post-edit (advisory): consult .ai/harness/context/change-impact-map.md — did this change stale a doc or toolchain surface? (change-impact-review)" >&2 ;;
  esac
fi
exit 0