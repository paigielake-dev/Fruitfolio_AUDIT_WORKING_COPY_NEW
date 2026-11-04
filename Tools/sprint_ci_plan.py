#!/usr/bin/env python3
"""Plan tagged sprint checks and preserve/cancel pre-sprint verification only."""
from datetime import datetime, timezone
from pathlib import Path
import json, os, subprocess, urllib.request

REPO = 'paigielake-dev/Fruitfolio_AUDIT_WORKING_COPY_NEW'
OLD_WORKFLOWS = {403220650, 403690677, 404497922}
PRESERVE = {41357420177, 41358742740}


def api(path, method='GET'):
    request = urllib.request.Request('https://api.github.com/repos/'+REPO+path,
        data=b'' if method == 'POST' else None, method=method,
        headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'], 'Accept':'application/vnd.github+json'})
    with urllib.request.urlopen(request, timeout=30) as response:
        raw=response.read(); return json.loads(raw) if raw else None


def should_run_verification(message, now, historical_deadline):
    return ('[continuation-verify]' in message
            or ('[sprint-verify]' in message and now < historical_deadline))


def main():
    assert os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('GITHUB_REPOSITORY') == REPO
    now=datetime.now(timezone.utc)
    clock=json.loads(Path('Delivery/FIVE_HOUR_SOURCE_SPRINT_CLOCK.json').read_text())
    inventory=[]
    for run in api('/actions/runs?per_page=100')['workflow_runs']:
        if run['head_branch'] != 'fruitfolio/prompt-1b-alignment' or run['workflow_id'] not in OLD_WORKFLOWS or run['status']=='completed' or run['id'] in PRESERVE: continue
        inventory.append({'run':run,'jobs':api(f"/actions/runs/{run['id']}/jobs?per_page=100"),'artifacts':api(f"/actions/runs/{run['id']}/artifacts?per_page=100")})
    out=Path('Fruitfolio_Verification_Evidence/Sprint');out.mkdir(parents=True,exist_ok=True)
    (out/'pre-sprint-run-inventory.json').write_text(json.dumps({'capturedAtUTC':now.isoformat(),'reason':'Explicit continuation verification after the historical sprint; original deadline preserved, MADLAD inference excluded. No artifact or commit deleted.','runs':inventory},indent=2)+'\n')
    # This job uploads the inventory in a separate step before cancellation.
    message=subprocess.check_output(['git','show','-s','--format=%s','HEAD'],text=True)
    deadline=datetime.fromisoformat(clock['finalDeadlineUTC'])
    # The original sprint deadline remains historical. A separately authorized
    # continuation tag permits current verification without resetting that clock.
    run_checks=should_run_verification(message, now, deadline)
    with open(os.environ['GITHUB_OUTPUT'],'a') as output:
        output.write('run_verification='+str(run_checks).lower()+'\n')
        output.write('run_recovery='+str('[sprint-recover]' in message and now<deadline).lower()+'\n')
    print('Tagged focused verification:',run_checks,'; MADLAD inference excluded. Inventory does not imply test acceptance.')

if __name__=='__main__': main()
