#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEME="${SCHEME:-Time Scopes}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
RESULTS_DIR="${RESULTS_DIR:-$ROOT_DIR/build/TestResults}"

select_destination() {
    if [[ -n "${DESTINATION:-}" ]]; then
        echo "$DESTINATION"
        return
    fi

    local available_devices
    available_devices="$(xcrun simctl list devices available)"

    local candidates=(
        "iPhone 17 Pro"
        "iPhone 17"
        "iPhone 16 Pro"
        "iPhone 16"
        "iPhone 15 Pro"
        "iPhone 15"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if printf '%s\n' "$available_devices" | rg -q "^[[:space:]]*${candidate} \\("; then
            echo "platform=iOS Simulator,name=${candidate}"
            return
        fi
    done

    local fallback
    fallback="$(printf '%s\n' "$available_devices" | awk -F '(' '/iPhone/ { gsub(/^ +| +$/, "", $1); print $1; exit }')"
    if [[ -n "$fallback" ]]; then
        echo "platform=iOS Simulator,name=${fallback}"
        return
    fi

    echo "No available iPhone simulator found." >&2
    exit 1
}

mkdir -p "$RESULTS_DIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-$RESULTS_DIR/TimeScopes-${TIMESTAMP}.xcresult}"
DESTINATION_VALUE="$(select_destination)"

echo "Scheme: $SCHEME"
echo "Destination: $DESTINATION_VALUE"
echo "Result bundle: $RESULT_BUNDLE_PATH"

xcodebuild \
    -scheme "$SCHEME" \
    -destination "$DESTINATION_VALUE" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE_PATH" \
    test

"$ROOT_DIR/scripts/ci/check_coverage.sh" "$RESULT_BUNDLE_PATH"
