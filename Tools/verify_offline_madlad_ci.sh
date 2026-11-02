#!/usr/bin/env bash
# Only for the disposable GitHub-hosted macOS verification VM. Never called by
# the application or normal local build instructions.
set -euo pipefail
if [[ "${GITHUB_ACTIONS:-}" != "true" || "${RUNNER_OS:-}" != "macOS" || "${RUNNER_ENVIRONMENT:-}" != "github-hosted" ]]; then
  echo "Offline isolation was not executed: a disposable GitHub-hosted macOS runner is required."
  exit 2
fi
: "${FRUITFOLIO_SIMULATOR_ID:?Actual booted simulator is required}"
# Separate finite isolation windows keep slow simulator startup/inference from
# turning one long watchdog expiry into false offline acceptance. Every required
# fixture still executes. A failed phase does not suppress later diagnostics.
if [[ $# == 0 ]]; then
  mkdir -p Fruitfolio_Verification_Evidence/MADLAD/Offline
  overall=0
  : > Fruitfolio_Verification_Evidence/MADLAD/Offline/phase-results.tsv
  for phase in core multilingual edge-quantities requested-languages expanded-medical; do
    set +e
    bash "$0" "$phase"
    phase_outcome=$?
    set -e
    printf '%s\t%s\n' "$phase" "$phase_outcome" >> Fruitfolio_Verification_Evidence/MADLAD/Offline/phase-results.tsv
    if [[ "$phase_outcome" != 0 ]]; then overall=1; fi
  done
  exit "$overall"
fi
phase="$1"
selectors=()
case "$phase" in
  native-grounding)
    selectors+=("-only-testing:FruitfolioTests/BundledNativeGroundingTests")
    selectors+=("-only-testing:FruitfolioUITests/AskGroundedJourneyUITests/testActualGroundedAnswerSourcesAndClearOnExit") ;;
  core)
    selectors+=("-only-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests/testOfficialModelExecutesLocallyThroughTheLinkedAppleRuntime")
    selectors+=("-only-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests/testCorruptTokenizerIsRejectedBeforeAnyModelInference")
    selectors+=("-only-testing:FruitfolioTests/BundledNativeGroundingTests")
    selectors+=("-only-testing:FruitfolioUITests/AskGroundedJourneyUITests/testActualGroundedAnswerSourcesAndClearOnExit") ;;
  multilingual)
    selectors+=("-only-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests/testMultilingualCandidatesExecuteWithOriginalMeasurementsCitationsAndParagraphLayout") ;;
  edge-quantities)
    selectors+=("-only-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests/testMultilingualEdgeQuantitiesExecuteWithoutChangingRecordedValuesOrWarnings") ;;
  requested-languages)
    selectors+=("-only-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests/testEveryRequestedLanguageExecutesOrReportsExactOfficialTagAbsenceWithoutSubstitution") ;;
  expanded-medical)
    selectors+=("-only-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests/testFifteenExpandedTargetsExecuteMedicalWarningPreservationWithoutClaimingMeaningApproval") ;;
  *) echo "Unknown offline phase"; exit 2 ;;
esac
evidence="Fruitfolio_Verification_Evidence/MADLAD/Offline/$phase"
result_bundle="Fruitfolio_Verification_Evidence/Build/OfflineMADLAD-$phase.xcresult"
log_name="xcode-offline-madlad-test.log"
if [[ "$phase" == native-grounding ]]; then
  evidence="Fruitfolio_Verification_Evidence/AI/OfflineNativeGrounding"
  result_bundle="Fruitfolio_Verification_Evidence/Build/OfflineNativeGrounding.xcresult"
  log_name="xcode-offline-native-grounding-test.log"
fi
mkdir -p "$evidence"
# pfctl may return nonzero when filtering is disabled. Inspect the actual
# status text; that is the required safe baseline, not a failure to restore.
set +e
sudo pfctl -s info > "$evidence/filter-before.txt" 2>&1
status_outcome=$?
set -e
printf '%s\n' "$status_outcome" > "$evidence/filter-before-exit-status.txt"
if ! /usr/bin/grep -q 'Status: Disabled' "$evidence/filter-before.txt"; then
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
    if ! /usr/bin/grep -q 'Status: Disabled' "$evidence/filter-restored-status.txt"; then
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
time.sleep(1080)
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
  "${selectors[@]}" \
  -resultBundlePath "$result_bundle" \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  2>&1 | tee "$evidence/$log_name"
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
echo "PASS: selected actual offline phase $phase executed while new external connections were blocked; loopback remained available to the local simulator. Physical-iPhone airplane-mode and general clinical/language acceptance remain separate."
