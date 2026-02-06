#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <xcresult-path>" >&2
    exit 64
fi

RESULT_BUNDLE_PATH="$1"
TARGET_NAME="${COVERAGE_TARGET_NAME:-Time Scopes.app}"
MIN_COVERAGE="${MIN_COVERAGE:-50.0}"
WIDGET_TARGET_NAME="${WIDGET_EXTENSION_COVERAGE_TARGET_NAME:-TimeScopesWidgetExtension.appex}"
MIN_WIDGET_COVERAGE="${MIN_COVERAGE_WIDGET_EXTENSION:-}"

if [[ ! -d "$RESULT_BUNDLE_PATH" ]]; then
    echo "xcresult not found: $RESULT_BUNDLE_PATH" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for coverage parsing." >&2
    exit 1
fi

resolve_coverage() {
    local target="$1"
    xcrun xccov view --report --json "$RESULT_BUNDLE_PATH" \
        | jq -r --arg target "$target" '.targets[] | select(.name == $target) | (.lineCoverage * 100)' \
        | head -n 1
}

ensure_target_exists() {
    local target="$1"
    local coverage="$2"
    if [[ -z "$coverage" || "$coverage" == "null" ]]; then
        echo "Coverage target not found: $target" >&2
        echo "Available targets:" >&2
        xcrun xccov view --report --json "$RESULT_BUNDLE_PATH" | jq -r '.targets[].name' | sed 's/^/ - /' >&2
        exit 1
    fi
}

check_gate() {
    local target="$1"
    local min_coverage="$2"
    local coverage
    coverage="$(resolve_coverage "$target")"
    ensure_target_exists "$target" "$coverage"

    printf "Coverage target: %s\n" "$target"
    printf "Current line coverage: %.2f%%\n" "$coverage"
    printf "Required minimum: %.2f%%\n" "$min_coverage"

    if ! awk "BEGIN { exit !($coverage >= $min_coverage) }"; then
        echo "Coverage gate failed for target: $target" >&2
        exit 1
    fi
}

check_gate "$TARGET_NAME" "$MIN_COVERAGE"

if [[ -n "$MIN_WIDGET_COVERAGE" ]]; then
    check_gate "$WIDGET_TARGET_NAME" "$MIN_WIDGET_COVERAGE"
fi

echo "Coverage gate passed."
