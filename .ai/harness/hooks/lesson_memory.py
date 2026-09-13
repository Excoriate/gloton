#!/usr/bin/env python3
# Codebase-harness generated-policy marker: bootstrap owns byte-exact installed copies.
"""Select scoped lessons and enforce one freshness policy for both memory heads."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any, Iterable
POLICY_SHA256 = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


POLICY_VERSION = "lesson-memory-v1"
RECEIPT_SCHEMA_VERSION = 1
FRESHNESS_MAX_AGE_DAYS = 30
SEVERITY_RANK = {"critical": 0, "high": 1, "medium": 2, "low": 3}
ALLOWED_TASK_PATH = re.compile(r"^[A-Za-z0-9._@+/-]+$")
PROTECTED_SEVERITIES = frozenset({"critical", "high"})
ALLOWED_GLOB = re.compile(r"^[A-Za-z0-9._@+/?*-]+$")
LESSON_ID = re.compile(r"^[A-Za-z0-9._@+-]+$")
ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
HOOK_LINE_LIMIT = 512
HOOK_SCOPE_ALERT_LIMIT = 10
HOOK_ALERT_LIMIT = 12
HOOK_SELECTED_ROW_LIMIT = 12


class LessonMemoryError(ValueError):
    """An input violates the lesson-memory contract."""


@dataclass(frozen=True)
class ScopeResult:
    status: str
    globs: tuple[str, ...]
    reason: str


@dataclass(frozen=True)
class FreshnessResult:
    state: str
    authority: str
    admitted: bool
    reason: str
    alert: str | None


def _lesson_id(entry: dict[str, Any], index: int) -> str:
    value = entry.get("id")
    return str(value) if value not in (None, "") else f"index-{index}"
def _severity(entry: dict[str, Any]) -> tuple[str, str]:
    raw = entry.get("severity")
    if raw in (None, ""):
        return "absent", "missing"
    if not isinstance(raw, str) or raw != raw.strip().lower() or raw not in SEVERITY_RANK:
        return "invalid", "invalid"
    return raw, "valid"




def _read_document(path: Path) -> tuple[Any, list[dict[str, Any]]]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise LessonMemoryError(f"LESSONS_READ_FAILED:{path}:{exc}") from exc
    if isinstance(document, list):
        raw_entries = document
    elif isinstance(document, dict) and isinstance(document.get("lessons"), list):
        raw_entries = document["lessons"]
    else:
        raise LessonMemoryError("LESSONS_SHAPE_INVALID:expected-array-or-lessons-array")
    if any(not isinstance(entry, dict) for entry in raw_entries):
        raise LessonMemoryError("LESSONS_ENTRY_INVALID:every-entry-must-be-object")
    seen_ids: set[str] = set()
    duplicates: set[str] = set()
    for index, entry in enumerate(raw_entries):
        lesson_id = _lesson_id(entry, index)
        if not LESSON_ID.fullmatch(lesson_id):
            raise LessonMemoryError(f"LESSON_ID_INVALID:{lesson_id!r}")
        if lesson_id in seen_ids:
            duplicates.add(lesson_id)
        seen_ids.add(lesson_id)
    if duplicates:
        raise LessonMemoryError(f"LESSONS_ID_DUPLICATE:{','.join(sorted(duplicates))}")
    return document, raw_entries


def _atomic_json_write(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(f".{path.name}.tmp-{os.getpid()}")
    try:
        temp.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        os.replace(temp, path)
    finally:
        if temp.exists():
            temp.unlink()


def _parse_iso_date(value: Any) -> date | None:
    if not isinstance(value, str) or not ISO_DATE.fullmatch(value):
        return None
    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def _validate_glob(value: Any) -> tuple[bool, str]:
    if not isinstance(value, str) or not value:
        return False, "glob-not-nonempty-string"
    if ";" in value:
        return False, "contains-semicolon-prose"
    if any(character.isspace() for character in value):
        return False, "contains-whitespace-or-prose"
    if not ALLOWED_GLOB.fullmatch(value):
        return False, "contains-unsupported-character"
    if value.startswith("/") or value.endswith("/") or "//" in value:
        return False, "not-normalized-repo-relative-path"
    parts = value.split("/")
    if any(part in ("", ".", "..") for part in parts):
        return False, "contains-invalid-path-segment"
    if any("**" in part and part != "**" for part in parts):
        return False, "double-star-must-be-whole-segment"
    all_recursive = all(part == "**" for part in parts)
    recursive_then_star = len(parts) > 1 and parts[-1] == "*" and all(
        part == "**" for part in parts[:-1]
    )
    if all_recursive or recursive_then_star:
        return False, "matches-entire-repository"
    return True, "valid"


def normalize_scope(raw_scope: Any) -> ScopeResult:
    if isinstance(raw_scope, str):
        valid, reason = _validate_glob(raw_scope)
        if not valid:
            return ScopeResult("unparseable", (), reason)
        return ScopeResult("migration-candidate", (raw_scope,), "legacy-scalar-glob")
    if isinstance(raw_scope, list) and raw_scope:
        normalized: list[str] = []
        for value in raw_scope:
            valid, reason = _validate_glob(value)
            if not valid:
                return ScopeResult("unparseable", (), reason)
            normalized.append(value)
        return ScopeResult("canonical", tuple(sorted(set(normalized))), "glob-list")
    return ScopeResult("unparseable", (), "scope-must-be-nonempty-glob-list")


def _glob_regex(pattern: str) -> re.Pattern[str]:
    translated: list[str] = ["^"]
    index = 0
    while index < len(pattern):
        character = pattern[index]
        if character == "*":
            if index + 1 < len(pattern) and pattern[index + 1] == "*":
                index += 2
                if index < len(pattern) and pattern[index] == "/":
                    translated.append("(?:.*/)?")
                    index += 1
                else:
                    translated.append(".*")
                continue
            translated.append("[^/]*")
        elif character == "?":
            translated.append("[^/]")
        else:
            translated.append(re.escape(character))
        index += 1
    translated.append("$")
    return re.compile("".join(translated))


def _normalize_task_path(value: str) -> str:
    if (
        not value
        or value.startswith(("/", "./"))
        or not ALLOWED_TASK_PATH.fullmatch(value)
    ):
        raise LessonMemoryError(f"TASK_PATH_INVALID:{value}")
    if any(part in ("", ".", "..") for part in value.split("/")):
        raise LessonMemoryError(f"TASK_PATH_INVALID:{value}")
    return value


def scope_matches(globs: Iterable[str], task_paths: Iterable[str]) -> bool:
    compiled = [_glob_regex(pattern) for pattern in globs]
    return any(pattern.fullmatch(path) for pattern in compiled for path in task_paths)


def _origin_date(entry: dict[str, Any]) -> tuple[str | None, str | None]:
    nested = entry.get("dates") if isinstance(entry.get("dates"), dict) else {}
    candidates = (
        ("last_validated", entry.get("last_validated")),
        ("dates.last_validated", nested.get("last_validated")),
        ("added", entry.get("added")),
        ("dates.added", nested.get("added")),
        ("dates.created", nested.get("created")),
        ("created", entry.get("created")),
        ("date", entry.get("date")),
    )
    for source, value in candidates:
        if _parse_iso_date(value) is not None:
            return source, value
    return None, None


def _coverage(entries: list[dict[str, Any]]) -> int:
    return sum(_parse_iso_date(entry.get("last_validated")) is not None for entry in entries)


def _entry_ids(entries: list[dict[str, Any]]) -> list[str]:
    return sorted(_lesson_id(entry, index) for index, entry in enumerate(entries))


def _enforcement_state(
    entries: list[dict[str, Any]], receipt_path: Path | None, corpus_sha256: str
) -> tuple[bool, str]:
    covered = _coverage(entries)
    if receipt_path is None or not receipt_path.is_file():
        return False, "backfill-receipt-missing"
    try:
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False, "backfill-receipt-invalid"
    if receipt.get("schema_version") != RECEIPT_SCHEMA_VERSION:
        return False, "backfill-receipt-schema-mismatch"
    if receipt.get("policy_version") != POLICY_VERSION:
        return False, "backfill-receipt-policy-mismatch"
    if receipt.get("policy_sha256") != POLICY_SHA256:
        return False, "backfill-receipt-policy-digest-mismatch"
    if receipt.get("coverage_complete") is not True:
        return False, "backfill-coverage-incomplete"
    if (
        receipt.get("entries_total") != len(entries)
        or receipt.get("covered_after") != len(entries)
        or receipt.get("unresolved_ids") != []
        or not isinstance(receipt.get("backfilled"), list)
    ):
        return False, "backfill-receipt-coverage-mismatch"
    if receipt.get("corpus_sha256_after") != corpus_sha256:
        return False, "backfill-receipt-corpus-mismatch"
    if receipt.get("entry_ids_after") != _entry_ids(entries):
        return False, "backfill-receipt-entry-set-mismatch"
    if covered != len(entries):
        return False, f"current-coverage-incomplete:{covered}/{len(entries)}"
    return True, "backfill-coverage-complete"


def _freshness_result(
    entry: dict[str, Any], index: int, as_of: date, enforcement_active: bool
) -> FreshnessResult:
    lesson_id = _lesson_id(entry, index)
    severity, severity_status = _severity(entry)
    validated = _parse_iso_date(entry.get("last_validated"))
    probe = (
        "probe=revalidate references then set top-level last_validated="
        f"{as_of.isoformat()} via codebase-harness-reflect"
    )
    if severity_status != "valid":
        reason = (
            "missing-severity-admitted"
            if severity_status == "missing"
            else f"invalid-severity:{entry.get('severity')!r}"
        )
        return FreshnessResult(
            "untyped-severity",
            "revalidation-required",
            True,
            reason,
            f"LESSON_SEVERITY_ALERT:{lesson_id}:{reason}:{probe}",
        )
    if validated is None:
        reason = "missing-or-invalid-top-level-last_validated"
        return FreshnessResult(
            "unvalidated-legacy",
            "revalidation-required",
            True,
            reason,
            f"LESSON_FRESHNESS_ALERT:{lesson_id}:{reason}:{probe}",
        )
    provenance = str(entry.get("last_validated_source", ""))
    if provenance and provenance != "backfill:dates.last_validated":
        if provenance.startswith("backfill:"):
            state = "backfilled-unvalidated"
            reason = f"synthetic-validation-date:{provenance}"
        else:
            state = "invalid-validation-provenance"
            reason = f"unknown-validation-provenance:{provenance}"
        return FreshnessResult(
            state,
            "revalidation-required",
            True,
            reason,
            f"LESSON_FRESHNESS_ALERT:{lesson_id}:{reason}:{probe}",
        )
    age_days = (as_of - validated).days
    if age_days < 0:
        reason = f"future-last-validated:{validated.isoformat()}"
        return FreshnessResult(
            "future-validation-date",
            "revalidation-required",
            True,
            reason,
            f"LESSON_FRESHNESS_ALERT:{lesson_id}:{reason}:{probe}",
        )
    if age_days <= FRESHNESS_MAX_AGE_DAYS:
        authority = "must-obey-current" if severity in PROTECTED_SEVERITIES else "current"
        return FreshnessResult("current", authority, True, f"age-days={age_days}", None)
    if not enforcement_active:
        reason = f"stale-age-days={age_days};enforcement-inert"
        return FreshnessResult(
            "stale-enforcement-inert",
            "enforcement-inert",
            True,
            reason,
            f"LESSON_FRESHNESS_ALERT:{lesson_id}:{reason}:{probe}",
        )
    if severity in PROTECTED_SEVERITIES:
        reason = f"stale-age-days={age_days};protected-severity={severity}"
        return FreshnessResult(
            "stale-protected",
            "revalidation-required",
            True,
            reason,
            f"LESSON_FRESHNESS_ALERT:{lesson_id}:{reason}:{probe}",
        )
    if severity not in SEVERITY_RANK:
        reason = f"stale-age-days={age_days};untyped-severity-admitted"
        return FreshnessResult(
            "stale-untyped-admitted",
            "revalidation-required",
            True,
            reason,
            f"LESSON_FRESHNESS_ALERT:{lesson_id}:{reason}:{probe}",
        )
    reason = f"stale-age-days={age_days};demoted-severity={severity}"
    return FreshnessResult(
        "stale-demoted",
        "quarantined",
        False,
        reason,
        f"LESSON_FRESHNESS_ALERT:{lesson_id}:{reason}:{probe}",
    )


def scope_report(entries: list[dict[str, Any]]) -> dict[str, Any]:
    grouped: dict[str, dict[str, Any]] = {}
    for index, entry in enumerate(entries):
        raw = entry.get("scope")
        raw_key = json.dumps(raw, sort_keys=True, ensure_ascii=False)
        row = grouped.setdefault(raw_key, {"raw": raw, "entry_ids": []})
        row["entry_ids"].append(_lesson_id(entry, index))
    rows: list[dict[str, Any]] = []
    for raw_key in sorted(grouped):
        grouped_row = grouped[raw_key]
        result = normalize_scope(grouped_row["raw"])
        rows.append(
            {
                "status": result.status,
                "raw": grouped_row["raw"],
                "normalized": list(result.globs),
                "reason": result.reason,
                "entry_ids": sorted(grouped_row["entry_ids"]),
            }
        )
    counts = {status: sum(row["status"] == status for row in rows) for status in (
        "canonical",
        "migration-candidate",
        "unparseable",
    )}
    return {"schema_version": 1, "distinct_raw_scopes": len(rows), "counts": counts, "rows": rows}


def freshness_payload(
    entries: list[dict[str, Any]],
    receipt_path: Path | None,
    as_of: date,
    corpus_sha256: str,
) -> dict[str, Any]:
    active, activation_reason = _enforcement_state(entries, receipt_path, corpus_sha256)
    rows: list[dict[str, Any]] = []
    for index, entry in enumerate(entries):
        result = _freshness_result(entry, index, as_of, active)
        rows.append(
            {
                "id": _lesson_id(entry, index),
                "severity": _severity(entry)[0],
                "state": result.state,
                "authority": result.authority,
                "admitted": result.admitted,
                "reason": result.reason,
                "alert": result.alert,
            }
        )
    must_obey = [row for row in rows if row["severity"] in PROTECTED_SEVERITIES]
    return {
        "schema_version": 1,
        "policy_version": POLICY_VERSION,
        "policy_sha256": POLICY_SHA256,
        "corpus_sha256": corpus_sha256,
        "as_of": as_of.isoformat(),
        "enforcement": {"active": active, "reason": activation_reason},
        "counts": {
            "total": len(rows),
            "admitted": sum(row["admitted"] for row in rows),
            "quarantined": sum(not row["admitted"] for row in rows),
            "must_obey_input": len(must_obey),
            "must_obey_admitted": sum(row["admitted"] for row in must_obey),
            "must_obey_current": sum(
                row["authority"] == "must-obey-current" for row in must_obey
            ),
            "high_input": sum(row["severity"] == "high" for row in rows),
            "high_admitted": sum(row["severity"] == "high" and row["admitted"] for row in rows),
        },
        "entries": rows,
    }


def select_payload(
    entries: list[dict[str, Any]],
    task_paths: Iterable[str],
    receipt_path: Path | None,
    as_of: date,
    limit: int,
    corpus_sha256: str,
) -> dict[str, Any]:
    normalized_paths = tuple(sorted(set(_normalize_task_path(path) for path in task_paths)))
    if not normalized_paths:
        raise LessonMemoryError("TASK_PATH_REQUIRED:selection-never-falls-back-to-unscoped")
    freshness = freshness_payload(entries, receipt_path, as_of, corpus_sha256)
    freshness_by_id = {row["id"]: row for row in freshness["entries"]}
    selected: list[dict[str, Any]] = []
    alerts: list[str] = []
    for index, entry in enumerate(entries):
        lesson_id = _lesson_id(entry, index)
        scope = normalize_scope(entry.get("scope"))
        if scope.status == "unparseable":
            alerts.append(f"LESSON_SCOPE_UNPARSEABLE:{lesson_id}:{scope.reason}")
            continue
        if not scope_matches(scope.globs, normalized_paths):
            continue
        if scope.status == "migration-candidate":
            alerts.append(f"LESSON_SCOPE_MIGRATION_CANDIDATE:{lesson_id}:{scope.globs[0]}")
        row = freshness_by_id[lesson_id]
        if row["alert"]:
            alerts.append(row["alert"])
        severity = row["severity"]
        if not row["admitted"]:
            continue
        selected.append(
            {
                "id": lesson_id,
                "severity": severity,
                "summary": str(entry.get("summary") or entry.get("lesson") or entry.get("title") or "?"),
                "scope_globs": list(scope.globs),
                "scope_status": scope.status,
                "freshness_state": row["state"],
                "authority": row["authority"],
            }
        )
    selected.sort(key=lambda row: (SEVERITY_RANK.get(row["severity"], 4), row["id"]))
    must_obey_current = [
        row for row in selected if row["authority"] == "must-obey-current"
    ]
    ordinary_current = [
        row for row in selected if row["authority"] == "current"
    ]
    revalidation_required = [
        row for row in selected if row["authority"] not in ("must-obey-current", "current")
    ]
    ordinary_total = len(ordinary_current)
    if limit > 0:
        ordinary_current = ordinary_current[:limit]
    visible = must_obey_current + ordinary_current + revalidation_required
    unique_alerts = sorted(set(alerts))
    scope_alerts = [alert for alert in unique_alerts if alert.startswith("LESSON_SCOPE_")]
    bounded_alerts = [
        alert for alert in unique_alerts if not alert.startswith("LESSON_SCOPE_")
    ]
    bounded_alerts.extend(scope_alerts[:HOOK_SCOPE_ALERT_LIMIT])
    scope_alerts_omitted = len(scope_alerts) - min(len(scope_alerts), HOOK_SCOPE_ALERT_LIMIT)
    if scope_alerts_omitted:
        bounded_alerts.append(
            f"LESSON_SCOPE_ALERTS_OMITTED:{scope_alerts_omitted}:run=lesson_memory.py scope-report"
        )
    return {
        "schema_version": 1,
        "policy_version": POLICY_VERSION,
        "policy_sha256": POLICY_SHA256,
        "corpus_sha256": corpus_sha256,
        "as_of": as_of.isoformat(),
        "task_paths": list(normalized_paths),
        "enforcement": freshness["enforcement"],
        "selection_counts": {
            "must_obey_current": len(must_obey_current),
            "ordinary_current": len(ordinary_current),
            "ordinary_omitted": ordinary_total - len(ordinary_current),
            "revalidation_required": len(revalidation_required),
            "scope_alerts_total": len(scope_alerts),
            "scope_alerts_omitted": scope_alerts_omitted,
        },
        "selected": visible,
        "alerts": bounded_alerts,
    }


def backfill(
    lessons_path: Path, receipt_path: Path, as_of: date, write_enabled: bool
) -> dict[str, Any]:
    if not write_enabled:
        raise LessonMemoryError("BACKFILL_WRITE_REQUIRED:pass---write-on-a-fixture-or-authorized-corpus")
    document, entries = _read_document(lessons_path)
    covered_before = _coverage(entries)
    backfilled: list[dict[str, str]] = []
    unresolved: list[str] = []
    for index, entry in enumerate(entries):
        if _parse_iso_date(entry.get("last_validated")) is not None:
            continue
        source, value = _origin_date(entry)
        if source is None or value is None:
            unresolved.append(_lesson_id(entry, index))
            continue
        entry["last_validated"] = value
        entry["last_validated_source"] = f"backfill:{source}"
        backfilled.append({"id": _lesson_id(entry, index), "source": source, "value": value})
    covered_after = _coverage(entries)
    if backfilled:
        _atomic_json_write(lessons_path, document)
    corpus_bytes = lessons_path.read_bytes()
    receipt = {
        "schema_version": RECEIPT_SCHEMA_VERSION,
        "policy_version": POLICY_VERSION,
        "policy_sha256": POLICY_SHA256,
        "as_of": as_of.isoformat(),
        "lessons_file": str(lessons_path),
        "entries_total": len(entries),
        "entry_ids_after": _entry_ids(entries),
        "covered_before": covered_before,
        "covered_after": covered_after,
        "coverage_complete": covered_after == len(entries),
        "backfilled": backfilled,
        "unresolved_ids": unresolved,
        "corpus_sha256_after": hashlib.sha256(corpus_bytes).hexdigest(),
    }
    _atomic_json_write(receipt_path, receipt)
    return receipt


def _date_arg(value: str) -> date:
    parsed = _parse_iso_date(value)
    if parsed is None:
        raise argparse.ArgumentTypeError("expected YYYY-MM-DD")
    return parsed


def _print_scope_lines(payload: dict[str, Any]) -> None:
    for row in payload["rows"]:
        if row["status"] == "migration-candidate":
            prefix = "MIGRATION-CANDIDATE"
        elif row["status"] == "canonical":
            prefix = "SCOPE-CANONICAL"
        else:
            prefix = "UNPARSEABLE-FLAGGED"
        print(
            f"{prefix}\t{json.dumps(row['raw'], ensure_ascii=False, sort_keys=True)}\t"
            f"{json.dumps(row['normalized'], ensure_ascii=False)}\t{row['reason']}"
        )
    print(
        "SCOPE-REPORT\t"
        f"distinct={payload['distinct_raw_scopes']}\t"
        f"canonical={payload['counts']['canonical']}\t"
        f"migration-candidate={payload['counts']['migration-candidate']}\t"
        f"unparseable={payload['counts']['unparseable']}"
    )


def _single_line(value: Any, limit: int = HOOK_LINE_LIMIT) -> str:
    text = re.sub(r"[\x00-\x1f\x7f]+", " ", str(value)).strip()
    return text[:limit]


def _print_hook(payload: dict[str, Any]) -> None:
    state = "active" if payload["enforcement"]["active"] else "inert"
    print(f"LESSON_SELECTOR:POLICY_SHA256:{payload['policy_sha256']}")
    print(f"LESSON_SELECTOR:AS_OF:{payload['as_of']}")
    print(f"LESSON_SELECTOR:ENFORCEMENT:{state}:{payload['enforcement']['reason']}")
    alerts = payload["alerts"]
    for alert in alerts[:HOOK_ALERT_LIMIT]:
        print(_single_line(alert))
    if len(alerts) > HOOK_ALERT_LIMIT:
        omitted_alerts = alerts[HOOK_ALERT_LIMIT:]
        digest = hashlib.sha256("\n".join(omitted_alerts).encode()).hexdigest()
        print(
            f"LESSON_ALERTS_OMITTED:{len(omitted_alerts)}:sha256={digest}:"
            "run=lesson_memory.py freshness --format lines"
        )
    selected = payload["selected"]
    if not selected:
        print("LESSON_SELECTOR:NO_IN_SCOPE_LESSONS")
        return
    for row in selected[:HOOK_SELECTED_ROW_LIMIT]:
        prefix = (
            "LESSON_REVALIDATION_REQUIRED"
            if row["authority"] in ("revalidation-required", "enforcement-inert")
            else "LESSON_SELECTED"
        )
        print(
            f"{prefix}:{_single_line(row['id'], 96)}:{_single_line(row['severity'], 24)}:"
            f"{_single_line(row['freshness_state'], 48)}:{_single_line(row['summary'], 280)}"
        )
    if len(selected) > HOOK_SELECTED_ROW_LIMIT:
        omitted_ids = [row["id"] for row in selected[HOOK_SELECTED_ROW_LIMIT:]]
        digest = hashlib.sha256("\n".join(omitted_ids).encode()).hexdigest()
        print(
            f"LESSON_ROWS_OMITTED:{len(omitted_ids)}:ids_sha256={digest}:"
            "run=codebase-harness-load"
        )


def _print_freshness_lines(payload: dict[str, Any]) -> None:
    state = "active" if payload["enforcement"]["active"] else "inert"
    print(f"LESSON_FRESHNESS:POLICY_SHA256:{payload['policy_sha256']}")
    print(f"LESSON_FRESHNESS:ENFORCEMENT:{state}:{payload['enforcement']['reason']}")
    for row in payload["entries"]:
        if row["alert"]:
            print(_single_line(row["alert"]))
    counts = payload["counts"]
    print(
        "LESSON_FRESHNESS:COUNTS:"
        f"total={counts['total']}:admitted={counts['admitted']}:quarantined={counts['quarantined']}:"
        f"must_obey_input={counts['must_obey_input']}:must_obey_admitted={counts['must_obey_admitted']}:"
        f"must_obey_current={counts['must_obey_current']}:"
        f"high_input={counts['high_input']}:high_admitted={counts['high_admitted']}"
    )

def _print_freshness_summary(payload: dict[str, Any]) -> None:
    state = "active" if payload["enforcement"]["active"] else "inert"
    counts = payload["counts"]
    print(f"LESSON_FRESHNESS:POLICY_SHA256:{payload['policy_sha256']}")
    print(f"LESSON_FRESHNESS:ENFORCEMENT:{state}:{payload['enforcement']['reason']}")
    print(
        "LESSON_FRESHNESS:SUMMARY:"
        f"total={counts['total']}:admitted={counts['admitted']}:quarantined={counts['quarantined']}:"
        f"must_obey_input={counts['must_obey_input']}:must_obey_admitted={counts['must_obey_admitted']}"
    )




def _effective_as_of(requested: date | None, allow_override: bool) -> date:
    today = date.today()
    if requested is None or requested == today:
        return requested or today
    if not allow_override:
        raise LessonMemoryError(
            f"AS_OF_OVERRIDE_REQUIRES_EXPLICIT_TEST_GATE:{requested.isoformat()}"
        )
    return requested


def _common_parser(subparsers: Any, name: str) -> argparse.ArgumentParser:
    parser = subparsers.add_parser(name)
    parser.add_argument("--lessons", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    grammar_parser = subparsers.add_parser("grammar")
    grammar_parser.add_argument("--format", choices=("json", "text"), default="text")

    scope_parser = _common_parser(subparsers, "scope-report")
    scope_parser.add_argument("--format", choices=("json", "lines"), default="lines")

    select_parser = _common_parser(subparsers, "select")
    select_parser.add_argument("--task-path", action="append", default=[])
    select_parser.add_argument("--receipt", type=Path)
    select_parser.add_argument("--as-of", type=_date_arg)
    select_parser.add_argument("--allow-clock-override", action="store_true")
    select_parser.add_argument("--limit", type=int, default=3)
    select_parser.add_argument("--format", choices=("json", "hook"), default="json")

    freshness_parser = _common_parser(subparsers, "freshness")
    freshness_parser.add_argument("--receipt", type=Path)
    freshness_parser.add_argument("--as-of", type=_date_arg)
    freshness_parser.add_argument("--allow-clock-override", action="store_true")
    freshness_parser.add_argument("--format", choices=("json", "lines", "summary"), default="lines")

    backfill_parser = _common_parser(subparsers, "backfill")
    backfill_parser.add_argument("--receipt", type=Path, required=True)
    backfill_parser.add_argument("--as-of", type=_date_arg)
    backfill_parser.add_argument("--allow-clock-override", action="store_true")
    backfill_parser.add_argument("--write", action="store_true")

    args = parser.parse_args(argv)
    try:
        if args.command == "grammar":
            payload = {
                "scope_key": "scope",
                "canonical_type": "non-empty-list-of-repo-relative-posix-globs",
                "wildcards": ["*", "**", "?"],
                "forbidden": [
                    "absolute",
                    "dot-segments",
                    "trailing-slash",
                    "whitespace",
                    "semicolon-prose",
                    "braces",
                    "double-star-inside-segment",
                    "**",
                    "**/*",
                ],
            }
            if args.format == "json":
                print(json.dumps(payload, indent=2, sort_keys=True))
            else:
                print("SCOPE-GRAMMAR:scope=non-empty-list-of-repo-relative-posix-globs:wildcards=*,**,?")
            return 0
        document, entries = _read_document(args.lessons)
        del document
        corpus_sha256 = hashlib.sha256(args.lessons.read_bytes()).hexdigest()
        if args.command == "scope-report":
            payload = scope_report(entries)
            if args.format == "json":
                print(json.dumps(payload, indent=2, sort_keys=True))
            else:
                _print_scope_lines(payload)
        elif args.command == "select":
            if args.limit < 0:
                raise LessonMemoryError("LIMIT_INVALID:must-be-zero-or-positive")
            as_of = _effective_as_of(args.as_of, args.allow_clock_override)
            payload = select_payload(
                entries, args.task_path, args.receipt, as_of, args.limit, corpus_sha256
            )
            if args.format == "hook":
                _print_hook(payload)
            else:
                print(json.dumps(payload, indent=2, sort_keys=True))
        elif args.command == "freshness":
            as_of = _effective_as_of(args.as_of, args.allow_clock_override)
            payload = freshness_payload(entries, args.receipt, as_of, corpus_sha256)
            if args.format == "json":
                print(json.dumps(payload, indent=2, sort_keys=True))
            elif args.format == "summary":
                _print_freshness_summary(payload)
            else:
                _print_freshness_lines(payload)
        elif args.command == "backfill":
            as_of = _effective_as_of(args.as_of, args.allow_clock_override)
            payload = backfill(args.lessons, args.receipt, as_of, args.write)
            print(json.dumps(payload, indent=2, sort_keys=True))
        return 0
    except LessonMemoryError as exc:
        print(f"LESSON_MEMORY_ERROR:{exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
