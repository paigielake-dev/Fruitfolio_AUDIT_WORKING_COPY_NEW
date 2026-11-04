#!/usr/bin/env python3
"""One founder-Mac command for all existing build/test batches; no MADLAD inference."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--simulator-id', required=True)
    p.add_argument('--source-commit', required=True)
    p.add_argument('--plan-only', action='store_true')
    args = p.parse_args()
    groups = ['build', 'unit', 'ui', 'audio', 'native']
    commands = [[sys.executable, 'Tools/verify_integrated_source_on_mac.py', '--group', group,
                 '--simulator-id', args.simulator_id, '--source-commit', args.source_commit] for group in groups]
    if args.plan_only:
        print(json.dumps({'status':'NOT EXECUTED', 'commands':commands,
                          'MADLADInference':'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT'}, indent=2)); return 0
    output = ROOT / 'Fruitfolio_Verification_Evidence/FounderMacContinuation' / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    output.mkdir(parents=True, exist_ok=False)
    results = []
    for group, command in zip(groups, commands):
        if results and results[0]['exitCode'] != 0:
            results.append({'group':group,'status':'BLOCKED — build/preflight failed','exitCode':None}); continue
        with (output / (group + '.log')).open('w') as log:
            proc = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            for line in proc.stdout:
                print(line, end='', flush=True); log.write(line); log.flush()
            code = proc.wait()
        results.append({'group':group,'command':command,'exitCode':code,
                        'status':'COMPLETED — inspect individual results and skips' if code==0 else 'FAIL OR NOT EXECUTED — inspect preflight/result logs'})
        (output / 'BatchResults.json').write_text(json.dumps({'sourceCommit':args.source_commit,'results':results,
            'releaseAcceptance':'NOT INFERRED','MADLADInference':'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT'},indent=2)+'\n')
    (output / 'BatchResults.json').write_text(json.dumps({'sourceCommit':args.source_commit,'results':results,
        'releaseAcceptance':'NOT INFERRED','MADLADInference':'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT'},indent=2)+'\n')
    return 0 if all(r['exitCode']==0 for r in results) else 1

if __name__ == '__main__':
    raise SystemExit(main())
