#!/usr/bin/env bash
# adr-next-number.sh — allocate the next safe ADR id for an append-only ADR ledger.
#
# Collision-safety (designed, not assumed):
#   - strict numeric extraction: only files matching NNNN- (4 digits) count; a non-numeric
#     template name like _adr-template.md is naturally ignored.
#   - git high-water: the next id is max(present, ever-committed-in-git)+1, so DELETING the
#     highest ADR cannot reuse its id (history remembers it).
#   - mkdir-lock: concurrent agents serialise on an atomic directory lock (no flock dependency).
#   - never reuses, never renumbers: ids are append-only.
#
# Usage: adr-next-number.sh [ADR_DIR]    (default: .ai/harness/adrs)
# Output: the zero-padded 4-digit next id (e.g. 0007) on stdout. Exit 0 on success, 1 on lock timeout.
#
# Portability: bash 3.2 (macOS) safe — no mapfile, no flock, no associative arrays.
set -euo pipefail

ADR_DIR="${1:-.ai/harness/adrs}"
LOCK_DIR="${ADR_DIR}/.adr-id.lock"

# Max 4-digit prefix among files PRESENT on disk (strict numeric; non-numeric names ignored).
_present_max() {
  local max=0 f base num
  [[ -d "$ADR_DIR" ]] || { printf '%s' 0; return 0; }
  for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
    [[ -e "$f" ]] || continue
    base="$(basename -- "$f")"
    num="${base:0:4}"
    case "$num" in (*[!0-9]*) continue ;; esac
    num=$((10#$num))
    if (( num > max )); then max=$num; fi
  done
  printf '%s' "$max"
}

# Max 4-digit prefix EVER committed under ADR_DIR (git history high-water).
_git_max() {
  local max=0 base num p
  command -v git >/dev/null 2>&1 || { printf '%s' 0; return 0; }
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf '%s' 0; return 0; }
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    base="${p##*/}"
    num="${base:0:4}"
    case "$num" in (*[!0-9]*) continue ;; esac
    num=$((10#$num))
    if (( num > max )); then max=$num; fi
  done < <(git log --all --pretty=format: --name-only --diff-filter=A -- "$ADR_DIR" 2>/dev/null \
           | grep -E '/[0-9]{4}-[^/]*\.md$' 2>/dev/null | sort -u || true)
  printf '%s' "$max"
}

_acquire_lock() {
  local i=0
  mkdir -p "$ADR_DIR" 2>/dev/null || true
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    i=$((i + 1))
    if (( i > 100 )); then
      printf 'adr-next-number: lock timeout on %s\n' "$LOCK_DIR" >&2
      return 1
    fi
    sleep 0.1
  done
  return 0
}
_release_lock() { rmdir "$LOCK_DIR" 2>/dev/null || true; }

_acquire_lock || exit 1
trap _release_lock EXIT INT TERM

present="$(_present_max)"
gitmax="$(_git_max)"
if (( present > gitmax )); then high=$present; else high=$gitmax; fi
next=$((high + 1))

printf '%04d\n' "$next"
