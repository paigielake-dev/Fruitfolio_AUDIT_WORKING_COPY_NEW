#!/usr/bin/env python3
"""Reconcile existing 478 IDs with source-sprint ledgers, never infer runtime PASS.

Keeps prior evidence as historical. The only retained narrow PASS decisions
require unchanged original implementation/test bytes and an actual recorded pass.
"""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {409, 418, 419, 420, 421, 422, 423, 424, 427, 428, 430, 436, 437, 438, 439, 441}
EXCLUDED_STATUS = 'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT'
PENDING = 'IMPLEMENTED — VERIFICATION PENDING'
RETAINED = {244, 245, 246}
# An authored change to one subcomponent does not complete these wider criteria.
PARTIAL_OVERRIDES = {70, 136, 143, 144, 183, 192, 193, 229, 232, 233, 234,
                     261, 326, 328, 329, 335, 336, 337, 359, 393, 397, 401,
                     458, 465, 472, 473, 474}


def values(value):
    if value is None: return []
    return value if isinstance(value, list) else [value]


def append_unique(target, additions):
    for entry in additions:
        if entry and entry not in target: target.append(entry)


def reconcile(document, ledgers, root, unchanged_evidence):
    items = document['requirements']
    assert len(items) == 478 and {r['requirementID'] for r in items} == {f'FF1B-{n:03}' for n in range(1, 479)}
    by_id = {r['requirementID']: r for r in items}
    records = {}
    for name, ledger in ledgers:
        for record in ledger.get('requirements', []):
            if record.get('requirementID') in by_id:
                records.setdefault(record['requirementID'], []).append((name, record))
    evidence_valid = (unchanged_evidence.get('modelBytesIdentical') is True
                      and unchanged_evidence.get('fixtureAndValidationTestPrefixIdentical') is True
                      and unchanged_evidence.get('historicalResult') == 'PASS')
    for item in items:
        rid = item['requirementID']; number = int(rid.rsplit('-', 1)[1])
        old = item['implementationStatus']
        item['preFiveHourAcceptanceStatus'] = item.get('preFiveHourAcceptanceStatus', old)
        historical = item.setdefault('historicalStatuses', [])
        tag = {'baseline': 'pre-five-hour-source-sprint acceptance', 'status': item['preFiveHourAcceptanceStatus']}
        if tag not in historical: historical.append(tag)
        item['currentSourceSprintChanges'] = []
        source_pending = old == 'PASS'
        status = PENDING if source_pending else ('NOT VERIFIED' if old == 'FAIL' else old)
        for ledger_path, record in records.get(rid, []):
            item['currentSourceSprintChanges'].append({'ledger': ledger_path, 'record': record})
            files = values(record.get('implementationFiles', record.get('sourceFiles')))
            append_unique(item.setdefault('relevantSourceFiles', []), files)
            append_unique(item.setdefault('changesMade', []), values(record.get('changes')))
            append_unique(item.setdefault('remainingIssues', []), values(record.get('remainingIssues', record.get('remainingIssue'))))
            requested = record.get('status', record.get('implementationStatus'))
            if requested == 'IMPLEMENTED': requested = PENDING
            if requested in {PENDING, 'PARTIAL', 'BLOCKED', 'NOT IMPLEMENTED'}: status = requested
            if record.get('specificationReference'):
                item['prompt1BSection'] = {**record['specificationReference'],
                    'exactCrossReferenceStatus': 'Mapped to the explicit authoritative correction; acceptance still requires applicable evidence'}
        if number in PARTIAL_OVERRIDES: status = 'PARTIAL'
        if number == 374: status = 'BLOCKED'
        if number in EXCLUDED:
            status = EXCLUDED_STATUS
            append_unique(item.setdefault('remainingIssues', []), [
                'MADLAD inference-dependent implementation/verification is expressly excluded from this source sprint. Existing official files, runtime and diagnostics are preserved. No new inference or medical-translation acceptance is claimed.'
            ])
        if number in RETAINED and evidence_valid:
            status = 'PASS'
            item['retainedAcceptanceBasis'] = {
                'scope': 'Unchanged numerical validation, decimal parsing and exact original unit-string behavior only; not changed UI/store/export or clinical interpretation',
                'actualTestSourceCommit': unchanged_evidence['historicalSourceCommit'],
                'evidence': 'Fruitfolio_Verification_Evidence/FiveHourSprint/Phase8Integration/UnchangedHormoneValidationEvidence.json',
                'newExecutionClaimed': False}
            append_unique(item.setdefault('supportingEvidence', []), [item['retainedAcceptanceBasis']['evidence']])
        elif old == 'PASS':
            append_unique(item.setdefault('remainingIssues', []), [
                'Historical PASS evidence is retained. Applicable integration/runtime acceptance has not been re-established after the source-sprint changes; this delivered revision is not automatically promoted.'
            ])
        if old == 'FAIL':
            item['lastKnownFailedAcceptance'] = {'status': 'FAIL',
                'basis': 'Preserved pre-sprint acceptance/tests; subsequent repairs are not a passing rerun.'}
            append_unique(item.setdefault('remainingIssues', []), [
                'Rerun the original strict failing journeys against the delivered source. Historical failed results remain open until actual passing evidence exists.'
            ])
        if number in {328, 329, 335, 336, 337}:
            append_unique(item.setdefault('remainingIssues', []), [
                'Catch mode retains rare standalone-star entry/settling. Classification controls currently lack standalone-star acquisition; no automatic award or invented substitute mechanic was added.'
            ])
        if number in {267, 268, 269, 270}:
            append_unique(item.setdefault('remainingIssues', []), [
                'A validated adjustment/calibration method and sufficient evidence/context have not been established. Actual points remain separate; no personalized concentrations or unsupported interpolated curves are invented.'
            ])
        if number in {229, 232, 233, 234}:
            append_unique(item.setdefault('remainingIssues', []), [
                'Local strict validation/shared persistence exists. Production identity reservation, comprehensive moderation and privacy-preserving real-name enforcement remain incomplete; no legal-name collection or fake backend was added.'
            ])
        if number in {393, 394, 395, 396, 397, 400, 401, 402, 403, 404, 405, 406, 435, 442}:
            append_unique(item.setdefault('remainingIssues', []), [
                'UI catalog has670 keys and60 individual choices;20 non-English choices have36 declared entries each. Full screen, writing-system, native-language and medical-content acceptance is not established by selector or catalog metadata.'
            ])
        known_files = item.get('relevantSourceFiles', [])
        existing = [p for p in known_files if (root / p.split('#')[0]).is_file()]
        missing = [p for p in known_files if not (root / p.split('#')[0]).is_file()]
        item['currentSourceFileInventory'] = {'existing': existing, 'missingOrCandidateOnly': missing,
            'meaning': 'Existence is structural evidence only; it does not establish implementation or runtime acceptance.'}
        if missing:
            append_unique(item.setdefault('remainingIssues', []), [
                'Some legacy candidate mappings do not resolve to files; see currentSourceFileInventory. They are not proof of absent app functionality and require item-level mapping repair.'
            ])
        item['implementationStatus'] = status
        item['finalDisposition'] = status
        item['acceptanceStatus'] = status
        item['currentVerification'] = {
            'actualResult': 'PASS — scoped unchanged implementation with recorded historical execution' if status == 'PASS' else
                            EXCLUDED_STATUS if status == EXCLUDED_STATUS else 'NOT VERIFIED for delivered integrated source',
            'newAppleExecution': False,
            'method': 'Existing requirement and recorded evidence reviewed with source-sprint ledger changes and file/provenance checks; no source-only runtime promotion',
            'historicalEvidenceRetained': True,
            'fullSpecificationCrossReference': item.get('prompt1BSection', {}).get('exactCrossReferenceStatus', 'Not established')}
        if status not in {'PASS', EXCLUDED_STATUS}:
            append_unique(item.setdefault('remainingIssues', []), [
                'Final integrated Mac/Xcode, simulator and applicable visual/accessibility/physical acceptance remains required; see Delivery/FOUNDER_MAC_VERIFICATION.md.'
            ])
        item['remainingDiscrepancies'] = list(item.get('remainingIssues', []))
    document['summary'] = dict(Counter(r['implementationStatus'] for r in items))
    document['completionClaim'] = False
    document['reconciledAtUTC'] = datetime.now(timezone.utc).isoformat()
    document['sourceSprintClock'] = 'Delivery/FIVE_HOUR_SOURCE_SPRINT_CLOCK.json'
    document['statusPolicy'] = ('All478 original IDs/references retained. No automatic source/build PASS. Scoped historical numerical validation is retained only with unchanged implementation/test proof. Other historical PASS/FAIL evidence remains separately identifiable; current acceptance is pending. NOT VERIFIED does not imply implementation absence. MADLAD inference is explicitly excluded, not passed. Full authoritative-spec cross-reference gaps remain explicit.')
    return document


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', help='Update existing tracker and human/index views; without this print proposed counts only')
    args = parser.parse_args()
    path = ROOT / 'Delivery/ImplementationTracker478.json'
    document = json.loads(path.read_text())
    ledgers = [(p.relative_to(ROOT).as_posix(), json.loads(p.read_text())) for p in sorted((ROOT / 'Delivery').glob('FiveHour_Phase*_RequirementChanges.json'))]
    unchanged = json.loads((ROOT / 'Fruitfolio_Verification_Evidence/FiveHourSprint/Phase8Integration/UnchangedHormoneValidationEvidence.json').read_text())
    model = (ROOT / 'Fruitfolio/Hormone Information/HormoneMeasurement.swift').read_bytes()
    unchanged['modelBytesIdentical'] = hashlib.sha1(b'blob ' + str(len(model)).encode() + b'\0' + model).hexdigest() == unchanged['historicalModelGitBlobSHA']
    tests = (ROOT / 'FruitfolioTests/HormoneMeasurementTests.swift').read_text()
    prefix = tests[:tests.index('    func testSaveEditRestartAndDeletePreserveRecords')]
    unchanged['fixtureAndValidationTestPrefixIdentical'] = hashlib.sha256(prefix.encode()).hexdigest() == unchanged['unchangedFixtureAndValidationPrefixSHA256']
    result = reconcile(document, ledgers, ROOT, unchanged)
    print(json.dumps({'requirements': len(result['requirements']), 'proposedSummary': result['summary'],
                      'applied': args.apply, 'releaseReady': False}, indent=2))
    if not args.apply: return
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    supplemental_path = ROOT / 'Delivery/SupplementalAcceptanceTracker.json'
    supplemental = json.loads(supplemental_path.read_text())
    for entry in supplemental.get('requirements', []):
        previous = entry.get('acceptanceStatus', 'NOT VERIFIED')
        entry.setdefault('preFiveHourAcceptanceStatus', previous)
        if entry.get('requirementID', '').startswith('SUP-MADLAD-'):
            entry['acceptanceStatus'] = EXCLUDED_STATUS
            entry['currentScope'] = 'Preserved files and earlier diagnostics only. No new MADLAD inference/medical-translation acceptance in this sprint.'
        elif previous == 'PASS':
            entry['acceptanceStatus'] = PENDING
            entry['currentScope'] = 'Historical passing evidence retained; changed integrated source requires applicable Mac verification.'
        entry['newAppleExecutionInSourceSprint'] = False
    supplemental['reconciledAtUTC'] = result['reconciledAtUTC']
    supplemental['summary'] = dict(Counter(r.get('acceptanceStatus', 'NOT VERIFIED') for r in supplemental.get('requirements', [])))
    supplemental['completionClaim'] = False
    supplemental_path.write_text(json.dumps(supplemental, ensure_ascii=False, indent=2) + '\n')

    lines = ['# Fruitfolio: final source-sprint requirement accounting', '',
             'All478 original checklist entries are retained below. This is an integrated-source handoff, not full Prompt1B or release acceptance. Exact authoritative-spec mappings remain incomplete where identified. Historical logs are not a new execution of the delivered source. MADLAD inference is excluded for the separate founder sprint.', '',
             '| Status | Count |', '|---|---:|']
    lines += [f'| {key} | {value} |' for key, value in result['summary'].items()]
    lines += ['', 'The three retained narrow PASS decisions use actual historical tests plus byte-identical hormone validation/model and fixture proof. They do not accept the changed store, UI, export, clinical meaning or full application. No new Apple test has executed in this source sprint.', '']
    for item in result['requirements']:
        lines += [f"## {item['requirementID']} — {item['implementationStatus']}", '',
                  item['originalBreakdownItem'], '', 'Original reference: ' + item['originalReference'], '',
                  'Source mappings: ' + '; '.join(item.get('relevantSourceFiles', [])), '',
                  'Current verification: ' + item['currentVerification']['actualResult'], '',
                  'Evidence: ' + '; '.join(item.get('supportingEvidence', []) + item.get('evidenceReferences', [])), '',
                  'Remaining discrepancies:']
        lines += ['- ' + str(issue).replace('\n', ' ') for issue in item['remainingDiscrepancies']]
        lines += ['']
    (ROOT / 'Delivery/FINAL_REQUIREMENT_STATUS_478.md').write_text('\n'.join(lines) + '\n')
    import csv
    with (ROOT / 'Fruitfolio_Verification_Evidence/requirement-to-evidence-index.csv').open('w', newline='') as stream:
        writer = csv.writer(stream)
        writer.writerow(['RequirementID', 'OriginalReference', 'ExactBreakdownRequirement', 'AcceptanceStatus', 'SourceFiles', 'ActualResult', 'Evidence', 'RemainingDiscrepancies'])
        for item in result['requirements']:
            writer.writerow([item['requirementID'], item['originalReference'], item['originalBreakdownItem'], item['implementationStatus'],
                             '; '.join(item.get('relevantSourceFiles', [])), item['currentVerification']['actualResult'],
                             '; '.join(item.get('supportingEvidence', []) + item.get('evidenceReferences', [])),
                             ' | '.join(item['remainingDiscrepancies'])])


if __name__ == '__main__':
    main()
