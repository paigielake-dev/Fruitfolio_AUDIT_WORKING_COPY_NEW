#!/usr/bin/env python3
"""Report individual XCTest executions without losing failures across runner restarts.

Only inspect an explicitly selected log; recursively mixing historical artifacts is
not supported. Summary lines are deliberately not the source of execution counts.
Swift Testing needs its own structured result report and is not counted here.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

CASE = re.compile(r"Test Case '([^']+)' (started|passed|failed|skipped)(?: \(([\d.]+) seconds\))?\.")


def summarize(text):
    executions = []
    pending = {}
    for line_number, line in enumerate(text.splitlines(), 1):
        match = CASE.search(line)
        if not match:
            continue
        name, state, duration = match.groups()
        if state == 'started':
            if name in pending:
                executions.append(dict(name=name, result='NOT VERIFIED', startLine=pending.pop(name), issue='Execution restarted without a terminal result'))
            pending[name] = line_number
        else:
            start = pending.pop(name, None)
            executions.append(dict(name=name, result={'passed': 'PASS', 'failed': 'FAIL', 'skipped': 'SKIPPED'}[state],
                                   startLine=start, resultLine=line_number,
                                   durationSeconds=float(duration) if duration else None))
    for name, start in pending.items():
        executions.append(dict(name=name, result='NOT VERIFIED', startLine=start, issue='No terminal result before log ended'))
    counts = {status: sum(row['result'] == status for row in executions) for status in ('PASS', 'FAIL', 'SKIPPED', 'NOT VERIFIED')}
    return dict(schemaVersion=1, scope='Individual XCTest executions in this exact log; not unique test cases, Swift Testing, or release acceptance',
                counts=counts, executionCount=len(executions),
                cleanExecution=bool(executions) and not counts['FAIL'] and not counts['NOT VERIFIED'], executions=executions)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    raw = args.log.read_bytes()
    result = summarize(raw.decode('utf-8', errors='strict'))
    result.update(log=str(args.log), logSHA256=hashlib.sha256(raw).hexdigest())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({key: result[key] for key in ('executionCount', 'counts', 'cleanExecution')}))


if __name__ == '__main__':
    main()
