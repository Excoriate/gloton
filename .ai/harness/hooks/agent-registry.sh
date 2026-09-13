#!/usr/bin/env bash
# shellcheck disable=SC2329
# Public helpers and callbacks are invoked by scripts that source this library.
# agent-registry.sh — parser for the declarative codebase-harness agent registry.
# Bash 3.2 compatible. Sourcing this file has no side effects.

_AGENT_REGISTRY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "${CODEBASE_HARNESS_AGENT_REGISTRY:-}" ]; then
  AGENT_REGISTRY_FILE="$CODEBASE_HARNESS_AGENT_REGISTRY"
elif [ -f "$_AGENT_REGISTRY_SCRIPT_DIR/../assets/data/agent-registry.tsv" ]; then
  AGENT_REGISTRY_FILE="$_AGENT_REGISTRY_SCRIPT_DIR/../assets/data/agent-registry.tsv"
elif [ -f "$_AGENT_REGISTRY_SCRIPT_DIR/../agent-registry.tsv" ]; then
  AGENT_REGISTRY_FILE="$_AGENT_REGISTRY_SCRIPT_DIR/../agent-registry.tsv"
else
  AGENT_REGISTRY_FILE="$_AGENT_REGISTRY_SCRIPT_DIR/agent-registry.tsv"
fi

ANTIGRAVITY_PERMISSION_POLICY_REQUIRED='toolPermission+enableTerminalSandbox-CONFIRMED;permissions-array-UNVERIFIED;precedence-UNKNOWN'

_agent_registry_stream() {
  [ -f "$AGENT_REGISTRY_FILE" ] || {
    printf 'agent registry not found: %s\n' "$AGENT_REGISTRY_FILE" >&2
    return 1
  }
  awk 'NF && $0 !~ /^[[:space:]]*#/' "$AGENT_REGISTRY_FILE"
  if [ -n "${CODEBASE_HARNESS_AGENT_REGISTRY_EXTRA:-}" ]; then
    [ -f "$CODEBASE_HARNESS_AGENT_REGISTRY_EXTRA" ] || {
      printf 'extra agent registry not found: %s\n' "$CODEBASE_HARNESS_AGENT_REGISTRY_EXTRA" >&2
      return 1
    }
    awk 'NF && $0 !~ /^[[:space:]]*#/' "$CODEBASE_HARNESS_AGENT_REGISTRY_EXTRA"
  fi
}

# id|display_name|subagent_capability|permission_capability|notes
agent_registry_rows() {
  _agent_registry_stream | awk -F'|' '$1 == "agent" { print $2 "|" $3 "|" $4 "|" $5 "|" $11 }'
}

agent_registry_row() {
  local wanted="$1"
  agent_registry_rows | awk -F'|' -v id="$wanted" '$1 == id { print; found=1; exit } END { if (!found) exit 1 }'
}

agent_registry_antigravity_permission_policy_valid() {
  local row _id _display _subagents permissions _notes
  row="$(agent_registry_row antigravity)" || return 1
  IFS='|' read -r _id _display _subagents permissions _notes <<EOF
$row
EOF
  [ "$permissions" = "$ANTIGRAVITY_PERMISSION_POLICY_REQUIRED" ]
}

agent_registry_count() {
  agent_registry_rows | /usr/bin/wc -l | tr -d ' '
}

# id|kind|path|mode|layout|suffix|dialect|evidence|ownership|notes
# Optional arguments filter by agent id, kind, then mode; "" and "all" mean any.
agent_registry_surfaces() {
  local wanted_agent="${1:-all}"
  local wanted_kind="${2:-all}"
  local wanted_mode="${3:-all}"
  _agent_registry_stream | awk -F'|' \
    -v a="$wanted_agent" -v k="$wanted_kind" -v m="$wanted_mode" '
      $1 == "surface" && (a == "" || a == "all" || $2 == a) &&
      (k == "" || k == "all" || $3 == k) &&
      (m == "" || m == "all" || $5 == m) {
        print $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 "|" $8 "|" $9 "|" $10 "|" $11
      }'
}

# id|purpose|path|scope|layout|evidence|ownership|notes
# Optional arguments filter by agent id, then purpose; "" and "all" mean any.
agent_registry_scans() {
  local wanted_agent="${1:-all}"
  local wanted_purpose="${2:-all}"
  _agent_registry_stream | awk -F'|' \
    -v a="$wanted_agent" -v p="$wanted_purpose" '
      $1 == "scan" && (a == "" || a == "all" || $2 == a) &&
      (p == "" || p == "all" || $3 == p) {
        print $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $9 "|" $10 "|" $11
      }'
}

# id|kind|path|evidence_tier|runtime_probe_id|activation_expectation|binary_path|binary_version|binary_sha256|probe_date|blocked_condition|claim_ceiling|notes
# Optional arguments filter by agent id, then exact surface path; "" and "all" mean any.
agent_registry_loadsets() {
  local wanted_agent="${1:-all}"
  local wanted_path="${2:-all}"
  _agent_registry_stream | awk -F'|' \
    -v a="$wanted_agent" -v p="$wanted_path" '
      $1 == "loadset" && (a == "" || a == "all" || $2 == a) &&
      (p == "" || p == "all" || $4 == p) {
        print $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 "|" $8 "|" $9 "|" $10 "|" $11 "|" $12 "|" $13 "|" $14
      }'
}

agent_registry_loadset() {
  local wanted_agent="$1"
  local wanted_path="$2"
  agent_registry_loadsets "$wanted_agent" "$wanted_path" |
    awk -F'|' 'NR == 1 { print; found=1 } END { if (!found) exit 1 }'
}

# id|path|dialect|key|expected_value|notes
agent_registry_activations() {
  local wanted_agent="${1:-all}"
  local wanted_path="${2:-all}"
  _agent_registry_stream | awk -F'|' \
    -v a="$wanted_agent" -v p="$wanted_path" '
      $1 == "activation" && (a == "" || a == "all" || $2 == a) &&
      (p == "" || p == "all" || $3 == p) {
        print $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7
      }'
}

_agent_registry_sha256() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{ print $1 }'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{ print $1 }'
  else
    printf 'no SHA-256 tool available\n' >&2
    return 1
  fi
}

# effective_tier|binary_path|recorded_version|live_version|live_sha256|probe_date|lease_status
agent_registry_effective_tier() {
  local wanted_agent="$1"
  local wanted_path="$2"
  local row id _kind _path tier _probe _activation binary_path binary_version recorded_sha probe_date
  local _blocked _claim _notes live_sha live_version

  row="$(agent_registry_loadset "$wanted_agent" "$wanted_path")" || return 1
  IFS='|' read -r id _kind _path tier _probe _activation binary_path binary_version \
    recorded_sha probe_date _blocked _claim _notes <<EOF
$row
EOF
  if [ ! -x "$binary_path" ]; then
    printf 'UNVERIFIED[blocked]:binary-missing:%s|%s|%s|||%s|blocked\n' \
      "$binary_path" "$binary_path" "$binary_version" "$probe_date"
    return 0
  fi
  live_sha="$(_agent_registry_sha256 "$binary_path")" || return 1
  if [ "$live_sha" != "$recorded_sha" ]; then
    printf 'UNVERIFIED[stale]|%s|%s||%s|%s|stale\n' \
      "$binary_path" "$binary_version" "$live_sha" "$probe_date"
    return 0
  fi
  if ! live_version="$(
    /usr/bin/perl -e 'my $pid=fork(); die "fork failed" unless defined $pid; if ($pid==0) { setpgrp(0,0); exec @ARGV; exit 127; } $SIG{ALRM}=sub { kill "TERM", -$pid; select undef,undef,undef,0.2; kill "KILL", -$pid; waitpid($pid,0); exit 124; }; alarm 25; waitpid($pid,0); my $status=$?; alarm 0; exit(($status & 127) ? 128+($status & 127) : $status >> 8);' -- "$binary_path" --version 2>&1
  )"; then
    live_version="$(printf '%s' "$live_version" | tr '\n|' '  ')"
    printf 'UNVERIFIED[blocked]:version-probe-failed|%s|%s|%s|%s|%s|blocked\n' \
      "$binary_path" "$binary_version" "$live_version" "$live_sha" "$probe_date"
    return 0
  fi
  live_version="$(printf '%s' "$live_version" | tr '\n|' '  ')"
  case "$live_version" in
    *"$binary_version"*) ;;
    *)
      printf 'UNVERIFIED[stale]|%s|%s|%s|%s|%s|stale\n' \
        "$binary_path" "$binary_version" "$live_version" "$live_sha" "$probe_date"
      return 0
      ;;
  esac
  printf '%s|%s|%s|%s|%s|%s|current\n' \
    "$tier" "$binary_path" "$binary_version" "$live_version" "$live_sha" "$probe_date"
}

agent_registry_trace() {
  local surface="$1"
  local agent_id="$2"
  [ -n "${CODEBASE_HARNESS_REGISTRY_TRACE:-}" ] || return 0
  printf '%s|%s\n' "$surface" "$agent_id" >> "$CODEBASE_HARNESS_REGISTRY_TRACE"
}

# Iterate every registered agent for a named consumer surface. The callback
# receives only fields with current Stage-1 consumers: id, display name, and
# subagent capability. Capability-specific callbacks query surfaces or the
# agent row directly; membership is never re-declared outside the registry.
agent_registry_for_each() {
  local surface="$1"
  local callback="$2"
  local rows id display subagents _permissions _notes
  rows="$(agent_registry_rows)" || return 1
  [ -n "$rows" ] || { echo "agent registry contains no agents" >&2; return 1; }
  while IFS='|' read -r id display subagents _permissions _notes; do
    [ -n "$id" ] || continue
    if [ -n "$surface" ]; then
      agent_registry_trace "$surface" "$id"
    fi
    "$callback" "$id" "$display" "$subagents"
  done <<EOF
$rows
EOF
}

agent_registry_validate() {
  local errors=0
  local records agents surfaces scans loadsets activations duplicates bad_records duplicate_emit
  local duplicate_loadsets duplicate_activations reserved_evidence
  local id display subagents permissions _notes kind path mode layout suffix dialect evidence ownership
  local purpose scope scan_count surface_count scan_surface_count overlap_conflict activation_count
  local agent_scans _scan_id _scan_purpose scan_root _scan_scope _scan_layout _scan_evidence _scan_ownership _scan_notes
  local tier probe_id activation_expectation binary_path binary_version binary_sha probe_date blocked_condition claim_ceiling
  local activation_key expected_value

  records="$(_agent_registry_stream)" || return 1
  agents="$(agent_registry_rows)" || return 1
  surfaces="$(agent_registry_surfaces)" || return 1
  scans="$(agent_registry_scans)" || return 1
  loadsets="$(agent_registry_loadsets)" || return 1
  activations="$(agent_registry_activations)" || return 1
  if [ -z "$agents" ]; then
    printf 'agent registry contains no agents\n' >&2
    return 1
  fi

  bad_records="$(printf '%s\n' "$records" | awk -F'|' '
    $1 == "agent" || $1 == "surface" || $1 == "scan" { if (NF != 11) print NR ":" $0; next }
    $1 == "loadset" { if (NF != 14) print NR ":" $0; next }
    $1 == "activation" { if (NF != 7) print NR ":" $0; next }
    { print NR ":" $0 }
  ')"
  if [ -n "$bad_records" ]; then
    printf 'invalid registry record(s), expected per-tag arity for agent|surface|scan|loadset|activation:\n%s\n' \
      "$bad_records" >&2
    errors=$((errors + 1))
  fi

  reserved_evidence="$(printf '%s\n' "$records" | awk -F'|' '
    ($1 == "surface" || $1 == "scan") && $9 ~ /PHASE0|TIER-[ABC]/ { print NR ":" $0 }
  ')"
  if [ -n "$reserved_evidence" ]; then
    printf 'invalid fabricated tier text in non-tier evidence field(s):\n%s\n' "$reserved_evidence" >&2
    errors=$((errors + 1))
  fi

  duplicates="$(printf '%s\n' "$agents" | awk -F'|' '{print $1}' | sort | uniq -d)"
  if [ -n "$duplicates" ]; then
    printf 'duplicate agent id(s): %s\n' "$duplicates" >&2
    errors=$((errors + 1))
  fi

  while IFS='|' read -r id display subagents permissions _notes; do
    [ -n "$id" ] || continue
    if [ -z "$display" ] || [ -z "$subagents" ] || [ -z "$permissions" ]; then
      printf 'incomplete agent row: %s\n' "$id" >&2
      errors=$((errors + 1))
    fi
    surface_count="$(printf '%s\n' "$surfaces" | awk -F'|' -v wanted="$id" '$1 == wanted { count++ } END { print count+0 }')"
    if [ "$surface_count" -eq 0 ]; then
      printf 'agent has no declared surfaces: %s\n' "$id" >&2
      errors=$((errors + 1))
    fi
    scan_count="$(printf '%s\n' "$scans" | awk -F'|' -v wanted="$id" '$1 == wanted && $2 == "placeholder" { count++ } END { print count+0 }')"
    if [ "$scan_count" -ne 1 ]; then
      printf 'agent must declare exactly one recursive placeholder root: %s count=%s\n' "$id" "$scan_count" >&2
      errors=$((errors + 1))
    fi
  done <<EOF
$agents
EOF

  if ! agent_registry_antigravity_permission_policy_valid; then
    printf 'invalid Antigravity permission evidence policy; required: %s\n' \
      "$ANTIGRAVITY_PERMISSION_POLICY_REQUIRED" >&2
    errors=$((errors + 1))
  fi

  while IFS='|' read -r id kind path mode layout suffix dialect evidence ownership _notes; do
    [ -n "$id" ] || continue
    if ! printf '%s\n' "$agents" | awk -F'|' -v wanted="$id" '$1 == wanted { found=1 } END { exit(found ? 0 : 1) }'; then
      printf 'surface references unknown agent: %s (%s %s)\n' "$id" "$kind" "$path" >&2
      errors=$((errors + 1))
    fi
    case "$kind" in instruction|rule|skill|agent|hook|config|sandbox|mcp) : ;;
      *) printf 'invalid surface kind: %s (%s %s)\n' "$kind" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    case "$mode" in emit|root-shared|read-shared|planned|preserve|forbidden) : ;;
      *) printf 'invalid surface mode: %s (%s %s)\n' "$mode" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    case "$layout" in root|nested|flat|directory|file) : ;;
      *) printf 'invalid surface layout: %s (%s %s)\n' "$layout" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    case "$dialect" in markdown|claude|skill|claude-agent|cursor|cursor-agent|json|yaml|codex-agent|toml|copilot|copilot-agent|omp|omp-agent|antigravity|antigravity-agent) : ;;
      *) printf 'invalid surface dialect: %s (%s %s)\n' "$dialect" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    if [ -z "$path" ] || [ -z "$evidence" ] || [ -z "$ownership" ]; then
      printf 'incomplete surface row: %s %s %s\n' "$id" "$kind" "$path" >&2
      errors=$((errors + 1))
    fi
    if [ "$mode" = "emit" ]; then
      case "$kind" in
        rule|skill|agent)
          if [ -z "$suffix" ]; then
            printf 'emitted %s surface has empty suffix: %s %s\n' "$kind" "$id" "$path" >&2
            errors=$((errors + 1))
          fi
          ;;
      esac
      if [ "$kind" = "rule" ] && { [ "$dialect" = "cursor" ] || [ "$dialect" = "omp" ]; }; then
        activation_count="$(printf '%s\n' "$activations" | awk -F'|' \
          -v wanted="$id" -v wanted_path="$path" \
          '$1 == wanted && $2 == wanted_path && $4 == "alwaysApply" { count++ } END { print count+0 }')"
        if [ "$activation_count" -ne 1 ]; then
          printf 'emitted %s rule surface requires exactly one alwaysApply activation expectation: %s %s count=%s\n' \
            "$dialect" "$id" "$path" "$activation_count" >&2
          errors=$((errors + 1))
        fi
      fi
    fi
  done <<EOF
$surfaces
EOF

  while IFS='|' read -r id purpose path scope layout evidence ownership _notes; do
    [ -n "$id" ] || continue
    if ! printf '%s\n' "$agents" | awk -F'|' -v wanted="$id" '$1 == wanted { found=1 } END { exit(found ? 0 : 1) }'; then
      printf 'scan root references unknown agent: %s (%s %s)\n' "$id" "$purpose" "$path" >&2
      errors=$((errors + 1))
    fi
    if [ "$purpose" != "placeholder" ]; then
      printf 'invalid scan purpose: %s (%s %s)\n' "$purpose" "$id" "$path" >&2
      errors=$((errors + 1))
    fi
    if [ "$scope" != "recursive" ] || [ "$layout" != "directory" ]; then
      printf 'placeholder scan must be a recursive directory root: %s scope=%s layout=%s path=%s\n' \
        "$id" "$scope" "$layout" "$path" >&2
      errors=$((errors + 1))
    fi
    case "$ownership" in exclusive|bounded) : ;;
      *) printf 'invalid placeholder root ownership: %s (%s %s)\n' "$ownership" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    if [ -z "$path" ] || [ -z "$evidence" ]; then
      printf 'incomplete scan root: %s %s %s\n' "$id" "$purpose" "$path" >&2
      errors=$((errors + 1))
    fi
    case "$path" in
      /*|.|..|./*|../*|*/../*|*/..|*//*|*/|*[[:upper:]]*)
        printf 'unsafe or non-canonical scan root path: %s (%s %s)\n' "$path" "$id" "$purpose" >&2
        errors=$((errors + 1))
        ;;
    esac
    case "$path" in
      .agents|.github)
        printf 'placeholder config root may not equal shared namespace: %s %s\n' "$id" "$path" >&2
        errors=$((errors + 1))
        ;;
    esac

    if [ "$ownership" = "bounded" ]; then
      if ! printf '%s\n' "$surfaces" | awk -F'|' -v wanted="$id" -v root="$path" '
        $1 == wanted && $4 == "emit" && $3 == root &&
        $6 != "root" && $6 != "file" && $9 == "shared" { found=1 }
        END { exit(found ? 0 : 1) }'; then
        printf 'bounded placeholder root must equal a shared emitted directory: %s %s\n' "$id" "$path" >&2
        errors=$((errors + 1))
      fi
    else
      scan_surface_count="$(printf '%s\n' "$surfaces" | awk -F'|' \
        -v wanted="$id" -v root="$path" '
          $1 == wanted && $4 == "emit" && $6 != "root" && $6 != "file" &&
          index($3, root "/") == 1 { count++ }
          END { print count+0 }')"
      if [ "$scan_surface_count" -eq 0 ]; then
        printf 'exclusive placeholder root must be a strict parent of an emitted directory: %s %s\n' "$id" "$path" >&2
        errors=$((errors + 1))
      fi
    fi
    overlap_conflict="$(printf '%s\n' "$scans" | awk -F'|' -v wanted="$id" -v root="$path" '
      !($1 == wanted && $3 == root) &&
      ($3 == root || index($3, root "/") == 1 || index(root, $3 "/") == 1) {
        print $1 ":" $3
        exit
      }')"
    if [ -n "$overlap_conflict" ]; then
      printf 'placeholder config roots overlap: %s %s with %s\n' \
        "$id" "$path" "$overlap_conflict" >&2
      errors=$((errors + 1))
    fi
  done <<EOF
$scans
EOF

  while IFS='|' read -r id kind path mode layout suffix dialect evidence ownership _notes; do
    [ -n "$id" ] || continue
    [ "$mode" = "emit" ] || continue
    case "$layout" in root|file) continue ;; esac
    agent_scans="$(agent_registry_scans "$id" placeholder)" || return 1
    IFS='|' read -r _scan_id _scan_purpose scan_root _scan_scope _scan_layout \
      _scan_evidence _scan_ownership _scan_notes <<EOF
$agent_scans
EOF
    case "$path" in
      "$scan_root"|"$scan_root"/*) : ;;
      *)
        printf 'emitted directory outside placeholder config root: %s %s %s root=%s\n' \
          "$id" "$kind" "$path" "$scan_root" >&2
        errors=$((errors + 1))
        ;;
    esac
  done <<EOF
$surfaces
EOF

  while IFS='|' read -r id kind path tier probe_id activation_expectation binary_path \
    binary_version binary_sha probe_date blocked_condition claim_ceiling _notes; do
    [ -n "$id" ] || continue
    if ! printf '%s\n' "$agents" | awk -F'|' -v wanted="$id" \
      '$1 == wanted { found=1 } END { exit(found ? 0 : 1) }'; then
      printf 'loadset references unknown agent: %s (%s)\n' "$id" "$path" >&2
      errors=$((errors + 1))
    fi
    if ! printf '%s\n' "$surfaces" | awk -F'|' -v wanted="$id" -v wanted_kind="$kind" -v wanted_path="$path" \
      '$1 == wanted && $2 == wanted_kind && $3 == wanted_path { found=1 } END { exit(found ? 0 : 1) }'; then
      printf 'loadset references unknown agent surface: %s %s %s\n' "$id" "$kind" "$path" >&2
      errors=$((errors + 1))
    fi
    case "$tier" in A|B|C) : ;;
      *) printf 'invalid loadset evidence_tier: %s (%s %s)\n' "$tier" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    case "$activation_expectation" in
      root-context|repo-instruction|registry-value-checked|file-touch-unobservable) : ;;
      *) printf 'invalid loadset activation expectation: %s (%s %s)\n' \
           "$activation_expectation" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    case "$probe_id" in
      phase0-*) : ;;
      *) printf 'invalid loadset runtime_probe_id: %s (%s %s)\n' "$probe_id" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    case "$binary_path" in
      /*) : ;;
      *) printf 'loadset binary path must be absolute: %s (%s %s)\n' "$binary_path" "$id" "$path" >&2; errors=$((errors + 1)) ;;
    esac
    if ! printf '%s\n' "$binary_sha" | awk '/^[0-9a-f]{64}$/ { ok=1 } END { exit(ok ? 0 : 1) }'; then
      printf 'invalid loadset binary SHA-256: %s (%s %s)\n' "$binary_sha" "$id" "$path" >&2
      errors=$((errors + 1))
    fi
    if ! printf '%s\n' "$probe_date" | awk '/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ { ok=1 } END { exit(ok ? 0 : 1) }'; then
      printf 'invalid loadset probe date: %s (%s %s)\n' "$probe_date" "$id" "$path" >&2
      errors=$((errors + 1))
    fi
    if [ -z "$binary_version" ] || [ -z "$claim_ceiling" ]; then
      printf 'incomplete loadset row: %s %s\n' "$id" "$path" >&2
      errors=$((errors + 1))
    fi
    if printf '%s\n' "$claim_ceiling" | awk 'BEGIN { IGNORECASE=1 } /provider accepted|model consumed|agent obeyed/ { found=1 } END { exit(found ? 0 : 1) }'; then
      printf 'loadset claim exceeds observable evidence: %s %s (%s)\n' "$id" "$path" "$claim_ceiling" >&2
      errors=$((errors + 1))
    fi
    if [ "$tier" = "C" ] && { [ -z "$blocked_condition" ] || [ "$blocked_condition" = "-" ]; }; then
      printf 'Tier C loadset requires a blocking condition: %s %s\n' "$id" "$path" >&2
      errors=$((errors + 1))
    fi
    if [ "$tier" != "C" ] && [ "$blocked_condition" != "-" ]; then
      printf 'Tier %s loadset must use blocked_condition=-: %s %s\n' "$tier" "$id" "$path" >&2
      errors=$((errors + 1))
    fi
  done <<EOF
$loadsets
EOF

  duplicate_loadsets="$(printf '%s\n' "$loadsets" | awk -F'|' '
    { key=$1 "|" $3; count[key]++ }
    END { for (key in count) if (count[key] > 1) print key ":" count[key] }
  ')"
  if [ -n "$duplicate_loadsets" ]; then
    printf 'duplicate loadset (client,surface) key(s):\n%s\n' "$duplicate_loadsets" >&2
    errors=$((errors + 1))
  fi

  while IFS='|' read -r id path dialect activation_key expected_value _notes; do
    [ -n "$id" ] || continue
    if ! printf '%s\n' "$surfaces" | awk -F'|' -v wanted="$id" -v wanted_path="$path" -v wanted_dialect="$dialect" \
      '$1 == wanted && $2 == "rule" && $3 == wanted_path && $7 == wanted_dialect { found=1 } END { exit(found ? 0 : 1) }'; then
      printf 'activation references unknown rule surface: %s %s %s\n' "$id" "$path" "$dialect" >&2
      errors=$((errors + 1))
    fi
    case "$dialect|$activation_key|$expected_value" in
      cursor\|alwaysApply\|source-type-governance|omp\|alwaysApply\|source-type-governance) : ;;
      *)
        printf 'invalid activation expectation: %s=%s (%s %s %s)\n' \
          "$activation_key" "$expected_value" "$id" "$path" "$dialect" >&2
        errors=$((errors + 1))
        ;;
    esac
  done <<EOF
$activations
EOF

  duplicate_activations="$(printf '%s\n' "$activations" | awk -F'|' '
    { key=$1 "|" $2 "|" $4; count[key]++ }
    END { for (key in count) if (count[key] > 1) print key ":" count[key] }
  ')"
  if [ -n "$duplicate_activations" ]; then
    printf 'duplicate activation expectation key(s):\n%s\n' "$duplicate_activations" >&2
    errors=$((errors + 1))
  fi
  duplicate_emit="$(printf '%s\n' "$surfaces" | awk -F'|' '$4 == "emit" { key=$1 "|" $2; count[key]++ } END { for (key in count) if (count[key] > 1) print key ":" count[key] }')"
  if [ -n "$duplicate_emit" ]; then
    printf 'multiple emitted surfaces for one agent/kind are unsupported:\n%s\n' "$duplicate_emit" >&2
    errors=$((errors + 1))
  fi

  [ "$errors" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    --agents)
      agent_registry_validate || exit 1
      agent_registry_rows
      ;;
    --surfaces)
      agent_registry_validate || exit 1
      agent_registry_surfaces "${2:-all}" "${3:-all}" "${4:-all}"
      ;;
    --scans)
      agent_registry_validate || exit 1
      agent_registry_scans "${2:-all}" "${3:-all}"
      ;;
    --loadsets)
      agent_registry_validate || exit 1
      agent_registry_loadsets "${2:-all}" "${3:-all}"
      ;;
    --activations)
      agent_registry_validate || exit 1
      agent_registry_activations "${2:-all}" "${3:-all}"
      ;;
    --effective-tier)
      [ "$#" -eq 3 ] || { printf 'Usage: %s --effective-tier AGENT SURFACE\n' "$0" >&2; exit 2; }
      agent_registry_validate || exit 1
      agent_registry_effective_tier "$2" "$3"
      ;;
    --count)
      agent_registry_validate || exit 1
      agent_registry_count
      ;;
    --validate)
      agent_registry_validate && printf 'agent registry valid: %s agents\n' "$(agent_registry_count)"
      ;;
    *)
      printf 'Usage: %s --validate|--count|--agents|--surfaces [agent] [kind] [mode]|--scans [agent] [purpose]|--loadsets [agent] [surface]|--activations [agent] [surface]|--effective-tier AGENT SURFACE\n' "$0" >&2
      exit 2
      ;;
  esac
fi
