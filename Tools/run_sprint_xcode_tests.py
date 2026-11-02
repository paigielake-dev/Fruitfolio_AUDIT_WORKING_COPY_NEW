#!/usr/bin/env python3
"""One selected Xcode batch; preserve failures and explicitly exclude MADLAD inference."""
import json, os, re, subprocess
from pathlib import Path
plan=json.loads(Path('Delivery/SprintVerificationPlan.json').read_text())
args=['xcodebuild','test-without-building','-project','Fruitfolio.xcodeproj','-scheme','Fruitfolio','-destination','platform=iOS Simulator,id='+os.environ['FRUITFOLIO_SIMULATOR_ID'],'-derivedDataPath','.ciDerivedData','-parallel-testing-enabled','NO','-resultBundlePath','Fruitfolio_Verification_Evidence/Build/SprintFocused.xcresult','CODE_SIGNING_ALLOWED=NO','ARCHS=arm64','ONLY_ACTIVE_ARCH=YES']
for key,prefix in [('onlyTesting','-only-testing:'),('skipTesting','-skip-testing:')]:
    for test in plan.get(key,[]):
        assert re.fullmatch('[A-Za-z0-9_/]+',test)
        args.append(prefix+test)
assert '-skip-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests' in args
out=Path('Fruitfolio_Verification_Evidence/Build');out.mkdir(parents=True,exist_ok=True)
with (out/'xcode-sprint-focused-test.log').open('w') as log:
    process=subprocess.Popen(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    for line in process.stdout: print(line,end='',flush=True);log.write(line);log.flush()
    result=process.wait()
subprocess.run(['python3','Tools/report_xctest_executions.py',str(out/'xcode-sprint-focused-test.log'),'--output',str(out/'sprint-individual-xctest-executions.json')],check=True)
raise SystemExit(result)
