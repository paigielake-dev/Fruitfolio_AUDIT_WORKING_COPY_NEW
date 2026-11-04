#!/usr/bin/env python3
"""Stop only inventoried pre-sprint workflows, preserving artifacts and outcomes."""
import json, os, urllib.error
from pathlib import Path
from sprint_ci_plan import api, REPO, OLD_WORKFLOWS, PRESERVE
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('GITHUB_REPOSITORY')==REPO
for item in json.loads(Path('Fruitfolio_Verification_Evidence/Sprint/pre-sprint-run-inventory.json').read_text())['runs']:
    run=api(f"/actions/runs/{item['run']['id']}")
    assert run['workflow_id'] in OLD_WORKFLOWS and run['head_branch']=='fruitfolio/prompt-1b-alignment' and run['id'] not in PRESERVE
    if run['status']=='completed': continue
    try:
        api(f"/actions/runs/{run['id']}/cancel",'POST')
        print('Stopped pre-sprint run',run['id'],'; existing results/artifacts retained, unfinished tests not passed.')
    except urllib.error.HTTPError as error:
        if error.code!=409: raise
