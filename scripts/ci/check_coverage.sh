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

if [[ ! -d "$RESULT_BUNDLE_PATH" ]]; then
    echo "xcresult not found: $RESULT_BUNDLE_PATH" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for coverage parsing." >&2
    exit 1
fi

COVERAGE="$(xcrun xccov view --report --json "$RESULT_BUNDLE_PATH" \
    | jq -r --arg target "$TARGET_NAME" '.targets[] | select(.name == $target) | (.lineCoverage * 100)' \
    | head -n 1)"

if [[ -z "$COVERAGE" || "$COVERAGE" == "null" ]]; then
    echo "Coverage target not found: $TARGET_NAME" >&2
    echo "Available targets:" >&2
    xcrun xccov view --report --json "$RESULT_BUNDLE_PATH" | jq -r '.targets[].name' | sed 's/^/ - /' >&2
    exit 1
fi

printf "Coverage target: %s\n" "$TARGET_NAME"
printf "Current line coverage: %.2f%%\n" "$COVERAGE"
printf "Required minimum: %.2f%%\n" "$MIN_COVERAGE"

if awk "BEGIN { exit !($COVERAGE >= $MIN_COVERAGE) }"; then
    echo "Coverage gate passed."
    exit 0
fi

echo "Coverage gate failed." >&2
exit 1
