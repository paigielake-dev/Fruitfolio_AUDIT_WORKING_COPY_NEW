#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null; then
  echo 'Xcode is required. Run this script on macOS with Xcode selected.' >&2
  exit 2
fi
: "${FRUITFOLIO_TEST_DESTINATION:?Set FRUITFOLIO_TEST_DESTINATION to platform=iOS Simulator,id=<available simulator UDID>}"
case "$FRUITFOLIO_TEST_DESTINATION" in
  *"platform=iOS Simulator"*)
    simulator_arch="${FRUITFOLIO_SIMULATOR_ARCHITECTURE:-$(uname -m)}"
    python3 Tools/verify_apple_runtime.py --target simulator --simulator-architecture "$simulator_arch"
    ;;
  *"platform=iOS,"*|"platform=iOS")
    python3 Tools/verify_apple_runtime.py --target device
    ;;
  *)
    echo 'Specify platform=iOS Simulator or platform=iOS in FRUITFOLIO_TEST_DESTINATION.' >&2
    exit 2
    ;;
esac
xcodebuild -version
xcodebuild -list -project Fruitfolio.xcodeproj
result="${TMPDIR:-/tmp}/Fruitfolio-Prompt1B-$(date +%Y%m%dT%H%M%S)-$$.xcresult"
echo "Xcode result bundle: $result"
xcodebuild -project Fruitfolio.xcodeproj -scheme Fruitfolio \
  -destination "$FRUITFOLIO_TEST_DESTINATION" \
  -resultBundlePath "$result" \
  -only-testing:FruitfolioTests \
  -only-testing:FruitfolioUITests/Prompt1BModalAccessibilityTests test
