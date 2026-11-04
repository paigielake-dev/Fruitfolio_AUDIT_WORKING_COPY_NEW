#!/usr/bin/env python3
"""Record real simulator pixels during smoke tests; no synthetic frames or audio."""
import argparse
import json
from pathlib import Path
import signal
import subprocess
import time

p = argparse.ArgumentParser()
p.add_argument('--udid', required=True)
p.add_argument('--output', required=True, type=Path)
p.add_argument('--seconds', type=float, default=60)
a = p.parse_args()
if not 1 <= a.seconds <= 120: raise SystemExit('Recording duration must be 1–120 seconds')
a.output.parent.mkdir(parents=True, exist_ok=True)
start = time.monotonic()
recording = subprocess.Popen(['xcrun','simctl','io',a.udid,'recordVideo','--codec=h264',str(a.output)])
try:
    time.sleep(a.seconds)
finally:
    if recording.poll() is None: recording.send_signal(signal.SIGINT)
    try: code = recording.wait(timeout=25)
    except subprocess.TimeoutExpired:
        recording.terminate()
        code = recording.wait(timeout=10)
result = {'simulator':a.udid,'wall_seconds':time.monotonic()-start,'return_code':code,
          'file_bytes':a.output.stat().st_size if a.output.exists() else 0,
          'scope':'Actual simulator pixels during smoke tests. Screen content still needs visual review. Audio is not recorded.'}
a.output.with_suffix('.recording.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
if not result['file_bytes']: raise SystemExit(1)
