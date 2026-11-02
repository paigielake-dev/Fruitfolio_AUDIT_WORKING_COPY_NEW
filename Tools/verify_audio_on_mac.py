#!/usr/bin/env python3
"""Build and run real audio-player tests on the founder Mac; never infer PASS."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', required=True,
                        help='Actual xcodebuild destination, e.g. platform=iOS Simulator,id=<UDID>')
    parser.add_argument('--source-commit', required=True, help='Exact integrated source commit being tested')
    parser.add_argument('--output', type=Path, default=Path('Fruitfolio_Verification_Evidence/FounderMacAudio'))
    args = parser.parse_args()
    if platform.system() != 'Darwin' or not shutil.which('xcodebuild'):
        parser.error('A Mac with Xcode is required. No build or runtime test has executed.')
    root = Path(__file__).resolve().parents[1]
    output = args.output if args.output.is_absolute() else root / args.output
    output = output / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    output.mkdir(parents=True, exist_ok=False)
    command = ['xcodebuild', 'test', '-project', 'Fruitfolio.xcodeproj', '-scheme', 'Fruitfolio',
               '-destination', args.destination, '-derivedDataPath', str(output / 'DerivedData'),
               '-resultBundlePath', str(output / 'Audio.xcresult'),
               '-parallel-testing-enabled', 'NO',
               '-only-testing:FruitfolioTests/AudioLifecycleRuntimeTests',
               '-only-testing:FruitfolioTests/TypingAudioRuntimeTests',
               'CODE_SIGNING_ALLOWED=NO']
    (output / 'Invocation.json').write_text(json.dumps({
        'sourceCommit': args.source_commit, 'command': command,
        'scope': 'Audio and typing runtime tests only; no MADLAD inference.',
        'acceptanceLimits': 'Posted-notification and player API tests do not verify audible quality, real calls or physical routes.'
    }, indent=2) + '\n')
    version = subprocess.run(['xcodebuild', '-version'], cwd=root, capture_output=True, text=True)
    (output / 'XcodeVersion.log').write_text(version.stdout + version.stderr)
    with (output / 'xcode-audio-test.log').open('w') as log:
        process = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            print(line, end='', flush=True)
            log.write(line)
            log.flush()
        code = process.wait()
    report = subprocess.run([sys.executable, 'Tools/report_xctest_executions.py',
                             str(output / 'xcode-audio-test.log'), '--output',
                             str(output / 'individual-executions.json')], cwd=root)
    (output / 'ProcessResults.json').write_text(json.dumps({
        'xcodebuildExitCode': code, 'reportExitCode': report.returncode,
        'note': 'Inspect individual executions and xcresult; an empty or unfinished run is not a pass.'
    }, indent=2) + '\n')
    return code if code else report.returncode


if __name__ == '__main__':
    raise SystemExit(main())
