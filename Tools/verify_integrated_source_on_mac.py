#!/usr/bin/env python3
"""Run one real founder-Mac verification batch, retaining evidence and failures.

Does not run MADLAD inference or alter the founder's network/firewall settings.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
MADLAD_SKIP = 'FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests'
GROUPS = {
    'library': ['FruitfolioTests/PhotoImportOwnershipTests',
                'FruitfolioTests/SavedSemanticByteIntegrityTests',
                'FruitfolioTests/Prompt10SavedLibraryTests',
                'FruitfolioTests/Prompt10LocalMediaStoreTests',
                'FruitfolioTests/LibraryBookshelfRenderingTests',
                'FruitfolioUITests/UserAuthoredPageUITests'],
    'ask': ['FruitfolioTests/AskSessionLifetimeTests',
            'FruitfolioTests/AskExcerptSelectionTests',
            'FruitfolioTests/AskSavedAttributionSnapshotTests',
            'FruitfolioTests/SemanticRenderSessionTests',
            'FruitfolioTests/EvidenceIdentitySafetyTests',
            'FruitfolioUITests/AskContinuousPaperUITests'],
    'introHub': ['FruitfolioTests/Prompt04IntroTests',
                 'FruitfolioTests/IntroInterruptionRuntimeTests',
                 'FruitfolioTests/Prompt07FirstLaunchTourTests',
                 'FruitfolioTests/TourInvitationLifecycleTests',
                 'FruitfolioUITests/SharedModalGuardUITests'],
    'shared': ['FruitfolioTests/ModalBackgroundRuntimeTests',
               'FruitfolioTests/SharedPopupCompositionTests',
               'FruitfolioTests/SharedDecorationLayoutTests',
               'FruitfolioTests/SharedControlArtworkTests',
               'FruitfolioTests/SemanticRenderSessionTests',
               'FruitfolioTests/PopupLayoutTests',
               'FruitfolioTests/SemanticUnicodeBoundaryTests',
               'FruitfolioUITests/SharedModalGuardUITests'],
    'unit': ['FruitfolioTests'],
    'ui': ['FruitfolioUITests'],
    'audio': ['FruitfolioTests/AudioLifecycleRuntimeTests', 'FruitfolioTests/TypingAudioRuntimeTests'],
    'native': ['FruitfolioTests/BundledNativeGroundingTests',
               'FruitfolioUITests/AskGroundedJourneyUITests/testActualGroundedAnswerSourcesAndClearOnExit'],
}


def commands(group, simulator, output):
    base = ['xcodebuild', 'build-for-testing' if group == 'build' else 'test',
            '-project', 'Fruitfolio.xcodeproj', '-scheme', 'Fruitfolio',
            '-destination', 'platform=iOS Simulator,id=' + simulator,
            '-derivedDataPath', str(output / 'DerivedData'),
            '-resultBundlePath', str(output / (group + '.xcresult')),
            '-parallel-testing-enabled', 'NO', 'CODE_SIGNING_ALLOWED=NO',
            'ARCHS=arm64', 'ONLY_ACTIVE_ARCH=YES']
    for selector in GROUPS.get(group, []):
        base.append('-only-testing:' + selector)
    base.append('-skip-testing:' + MADLAD_SKIP)
    if group == 'unit':
        base.append('-skip-testing:FruitfolioTests/BundledNativeGroundingTests')
    return base


def run_logged(command, destination):
    with destination.open('w') as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            print(line, end='', flush=True)
            log.write(line)
            log.flush()
        return process.wait()


def source_hashes():
    result = {}
    for folder in ['Fruitfolio', 'FruitfolioTests', 'FruitfolioUITests', 'Fruitfolio.xcodeproj']:
        for path in sorted((ROOT / folder).rglob('*')):
            if path.is_file() and path.suffix in {'.swift', '.pbxproj', '.xcscheme', '.plist', '.xcstrings'}:
                result[path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--group', required=True, choices=['build', *GROUPS])
    parser.add_argument('--simulator-id', required=True, help='An existing available iPhone simulator UDID')
    parser.add_argument('--source-commit', required=True, help='Exact delivered GitHub commit, not an old local clone HEAD')
    parser.add_argument('--output', type=Path, default=Path('Fruitfolio_Verification_Evidence/FounderMac'))
    parser.add_argument('--plan-only', action='store_true', help='Print commands only; no execution or PASS')
    args = parser.parse_args()
    if not re.fullmatch(r'[a-f0-9]{40}', args.source_commit):
        parser.error('A real full 40-character delivered commit is required')
    if not re.fullmatch(r'[A-Fa-f0-9-]{36}', args.simulator_id):
        parser.error('Use the actual simulator UDID from xcrun simctl list devices available')
    output = (args.output if args.output.is_absolute() else ROOT / args.output)
    output = output / (datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '-' + args.group)
    command = commands(args.group, args.simulator_id, output)
    if args.plan_only:
        print(json.dumps({'status': 'NOT EXECUTED', 'command': command,
                          'MADLADInference': 'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT'}, indent=2))
        return 0
    output.mkdir(parents=True, exist_ok=False)
    report = {'sourceCommit': args.source_commit, 'sourceIdentity': 'Caller-supplied delivered commit plus actual file hashes',
              'group': args.group, 'startedAtUTC': datetime.now(timezone.utc).isoformat(),
              'command': command, 'status': 'NOT EXECUTED', 'MADLADInference': 'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT',
              'offlineAcceptance': 'NOT VERIFIED — runner does not change or prove network isolation',
              'limits': 'Test execution is not full visual, clinical, audible-quality, physical-device or 478-item release acceptance.'}
    result_path = output / 'ExecutionStatus.json'
    def save():
        result_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    save()
    if platform.system() != 'Darwin' or not shutil.which('xcodebuild') or not shutil.which('xcrun'):
        report['blocker'] = 'A Mac with Xcode and simulator tools is required; no Apple command executed.'
        save(); print(report['blocker'], file=sys.stderr); return 2
    if platform.machine() != 'arm64':
        report['blocker'] = 'Delivered runtime simulator slices require an Apple Silicon Mac; no x86_64 simulator slice is included.'
        save(); print(report['blocker'], file=sys.stderr); return 2
    try:
        run_logged(['xcodebuild', '-version'], output / 'XcodeVersion.log')
        devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json'], text=True))
        (output / 'AvailableSimulators.json').write_text(json.dumps(devices, indent=2) + '\n')
        device = next((d for group in devices['devices'].values() for d in group if d['udid'] == args.simulator_id), None)
        if device is None or 'iPhone' not in device['name']:
            raise RuntimeError('The supplied UDID is not an available iPhone simulator')
        if device['state'] != 'Booted':
            subprocess.run(['xcrun', 'simctl', 'boot', args.simulator_id], check=True)
        subprocess.run(['xcrun', 'simctl', 'bootstatus', args.simulator_id, '-b'], check=True)
        if args.group == 'ui':
            subprocess.run(['xcrun', 'simctl', 'addmedia', args.simulator_id,
                            str(ROOT / 'Fruitfolio/Assets.xcassets/Art/Decor/decor_fluffy_cloud.imageset/decor_fluffy_cloud.png')], check=True)
        (output / 'ActualSourceSHA256.json').write_text(json.dumps(source_hashes(), indent=2) + '\n')
        report['status'] = 'RUNNING'; save()
        code = run_logged(command, output / 'xcode.log')
        report['xcodebuildExitCode'] = code
        if args.group == 'build':
            report['status'] = 'PASS' if code == 0 else 'FAIL'
            report['scope'] = 'Build-for-testing only. No tests or application journeys executed.'
        else:
            from report_xctest_executions import summarize
            raw = (output / 'xcode.log').read_bytes()
            cases = summarize(raw.decode('utf-8', errors='strict'))
            cases['logSHA256'] = hashlib.sha256(raw).hexdigest()
            (output / 'IndividualXCTestExecutions.json').write_text(json.dumps(cases, indent=2) + '\n')
            report['XCTestCounts'] = cases['counts']
            report['status'] = ('PASS WITH SKIPS' if cases['counts']['SKIPPED'] else 'PASS') if code == 0 and cases['cleanExecution'] else 'FAIL'
            report['scope'] = 'Exact selected executions. Swift Testing results remain in xcode.log/xcresult and must be recorded separately.'
        bundle = output / (args.group + '.xcresult')
        if bundle.exists():
            export = ['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(bundle),
                      '--output-path', str(output / 'Attachments')]
            report['attachmentExportExitCode'] = run_logged(export, output / 'AttachmentExport.log')
            # Retain the native result even when attachment export is unavailable.
        report['finishedAtUTC'] = datetime.now(timezone.utc).isoformat()
        save()
        return 0 if report['status'] in {'PASS', 'PASS WITH SKIPS'} else 1
    except (OSError, RuntimeError, subprocess.SubprocessError, ValueError) as error:
        report['status'] = 'FAIL' if report['status'] == 'RUNNING' else 'NOT EXECUTED'
        report['error'] = str(error); save()
        print(str(error), file=sys.stderr); return 2


if __name__ == '__main__':
    raise SystemExit(main())
