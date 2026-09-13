#!/usr/bin/env bash
# codebase-harness-verification-route: discriminating
# Portable harness verifier. Both arms enter through the repository Justfile.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
if [[ -f .verification-disposable ]]; then
    export CARGO_NET_OFFLINE=true
fi


case "${1-}" in
    "")
        exec just ci
        ;;
    --negative)
        probe=".cursor/rules/__verification_markerless_probe__.mdc"
        trap 'rm -f "$probe"' EXIT HUP INT TERM
        printf '%s\n' "markerless duplicate policy owner" >"$probe"

        set +e
        output="$(just test --test harness 2>&1)"
        status=$?
        set -e

        if [[ $status -eq 0 ]]; then
            printf '%s\n' "negative control escaped: markerless rule was accepted" >&2
            exit 0
        fi
        if [[ "$output" != *"__verification_markerless_probe__.mdc"* ]]; then
            printf '%s\n' "$output" >&2
            printf '%s\n' "negative control failed for an unrelated reason" >&2
            exit 0
        fi

        printf '%s\n' "negative control rejected: markerless rule detected" >&2
        exit "$status"
        ;;
    *)
        printf 'usage: %s [--negative]\n' "$0" >&2
        exit 64
        ;;
esac
