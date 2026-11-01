#!/usr/bin/env bash
# Only for the disposable GitHub-hosted macOS verification VM. Never called by
# the application or normal local build instructions.
set -euo pipefail
if [[ "${GITHUB_ACTIONS:-}" != "true" || "${RUNNER_OS:-}" != "macOS" || "${RUNNER_ENVIRONMENT:-}" != "github-hosted" ]]; then
  echo "Offline isolation was not executed: a disposable GitHub-hosted macOS runner is required."
  exit 2
fi
: "${FRUITFOLIO_SIMULATOR_ID:?Actual booted simulator is required}"
evidence="Fruitfolio_Verification_Evidence/MADLAD/Offline"
mkdir -p "$evidence"
sudo pfctl -s info > "$evidence/filter-before.txt" 2>&1
if ! rg -q 'Status: Disabled' "$evidence/filter-before.txt"; then
  echo "Offline isolation was not executed: an existing active firewall will not be replaced."
  exit 2
fi
# Establish a real reachable origin before isolation, rather than mistake an
# unrelated service/DNS outage for a successful controlled offline test.
curl --head --connect-timeout 5 --max-time 10 https://huggingface.co/ \
  > "$evidence/origin-reachable-before.txt" 2>&1
cat > "$evidence/offline.pf.conf" <<'RULES'
set skip on lo0
block drop out quick all
RULES
sudo pfctl -nf "$evidence/offline.pf.conf"
watchdog_pid=""
filter_changed=0
restore() {
  local outcome=$?
  trap - EXIT INT TERM
  if [[ -n "$watchdog_pid" ]]; then kill "$watchdog_pid" 2>/dev/null || true; fi
  if [[ "$filter_changed" == 1 ]]; then
    sudo pfctl -d >> "$evidence/filter-restoration.txt" 2>&1 || true
    sudo pfctl -f /etc/pf.conf >> "$evidence/filter-restoration.txt" 2>&1 || true
    sudo pfctl -s info > "$evidence/filter-restored-status.txt" 2>&1 || true
    if ! rg -q 'Status: Disabled' "$evidence/filter-restored-status.txt"; then
      echo "FAIL: runner filtering was not restored to its original disabled state."
      outcome=6
    fi
  fi
  exit "$outcome"
}
trap restore EXIT INT TERM
filter_changed=1
sudo pfctl -f "$evidence/offline.pf.conf" > "$evidence/filter-enable.txt" 2>&1
sudo pfctl -e >> "$evidence/filter-enable.txt" 2>&1
sudo pfctl -sr > "$evidence/actual-block-rules.txt" 2>&1
# Independent restoration protects the ephemeral runner if the test harness
# hangs. If it fires, the test is explicitly rejected as offline evidence.
python3 - "$evidence" > "$evidence/watchdog-restoration.txt" 2>&1 <<'PYWATCHDOG' &
import pathlib, subprocess, sys, time
time.sleep(480)
pathlib.Path(sys.argv[1], 'isolation-ended-before-test-completed').touch()
for command in [['sudo', 'pfctl', '-d'], ['sudo', 'pfctl', '-f', '/etc/pf.conf']]:
    subprocess.run(command, check=False, stdout=sys.stdout, stderr=subprocess.STDOUT)
PYWATCHDOG
watchdog_pid=$!
if curl --head --connect-timeout 3 --max-time 5 https://huggingface.co/ > "$evidence/origin-blocked-before-inference.txt" 2>&1; then
  echo "FAIL: external origin remained reachable; no offline inference acceptance."
  exit 3
fi
set +e
set -o pipefail
xcodebuild test-without-building -project Fruitfolio.xcodeproj -scheme Fruitfolio \
  -destination "platform=iOS Simulator,id=$FRUITFOLIO_SIMULATOR_ID" \
  -derivedDataPath .ciDerivedData -parallel-testing-enabled NO \
  -disableAutomaticPackageResolution \
  -only-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests \
  -only-testing:FruitfolioTests/BundledNativeGroundingTests \
  -only-testing:FruitfolioUITests/AskGroundedJourneyUITests/testActualGroundedAnswerSourcesAndClearOnExit \
  -resultBundlePath Fruitfolio_Verification_Evidence/Build/OfflineMADLAD.xcresult \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  2>&1 | tee "$evidence/xcode-offline-madlad-test.log"
test_outcome=$?
set -e
if [[ -e "$evidence/isolation-ended-before-test-completed" ]]; then
  echo "FAIL: watchdog ended isolation before test completion; no offline PASS."
  exit 4
fi
if curl --head --connect-timeout 3 --max-time 5 https://huggingface.co/ > "$evidence/origin-blocked-after-inference.txt" 2>&1; then
  echo "FAIL: external origin became reachable during the test; no offline PASS."
  exit 5
fi
if [[ "$test_outcome" != 0 ]]; then exit "$test_outcome"; fi
echo "PASS: actual bundled official MADLAD and strict native FruitfolioAI grounding fixtures plus the Ask answer/return UI journey executed while new external connections were blocked; loopback remained available to the local simulator. Physical-iPhone airplane-mode and general clinical/language acceptance remain separate."
