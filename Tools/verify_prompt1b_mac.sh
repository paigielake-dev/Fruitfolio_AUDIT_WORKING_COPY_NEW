#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null; then
  echo 'Xcode is required. Run this script on macOS with Xcode selected.' >&2
  exit 2
fi
: "${FRUITFOLIO_TEST_DESTINATION:?Set FRUITFOLIO_TEST_DESTINATION to platform=iOS Simulator,id=<available simulator UDID>}"
python3 Tools/verify_apple_runtime.py
xcodebuild -version
xcodebuild -list -project Fruitfolio.xcodeproj
result="${TMPDIR:-/tmp}/Fruitfolio-Prompt1B-$(date +%Y%m%dT%H%M%S)-$$.xcresult"
xcodebuild -project Fruitfolio.xcodeproj -scheme Fruitfolio \
  -destination "$FRUITFOLIO_TEST_DESTINATION" \
  -resultBundlePath "$result" \
  -only-testing:FruitfolioTests \
  -only-testing:FruitfolioUITests/Prompt1BModalAccessibilityTests test
