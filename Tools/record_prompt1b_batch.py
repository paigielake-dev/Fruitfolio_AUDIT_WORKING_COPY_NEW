#!/usr/bin/env python3
"""Record one verified local batch without promoting whole-requirement status.

Each manifest must explicitly distinguish executed, unexecuted and remaining
verification. Original checklist identity/text/order and unrelated rows remain.
"""
import argparse, json, subprocess, datetime, re
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--batch', type=Path, required=True)
parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
args = parser.parse_args()
root = args.root.resolve(); workflow = root / 'development_workflow'
b = json.loads(args.batch.read_text())
if not isinstance(b.get('batch'), str) or re.fullmatch(r'[A-Za-z0-9_-]+', b['batch']) is None:
    parser.error('batch must be a simple unique checkpoint name')
if (workflow / 'RUN_LOGS' / (b['batch'] + '.json')).exists():
    parser.error('this batch already has a run log; preserve it and use a new checkpoint name')
for key in ['files', 'tests', 'commands']:
    if not isinstance(b.get(key), list) or not all(isinstance(value, str) for value in b[key]):
        parser.error(key + ' must be an explicit list of strings')
if not isinstance(b.get('summary'), str) or not isinstance(b.get('next'), str) or not isinstance(b.get('results'), dict):
    parser.error('summary, next action and test results must be explicit')
if type(b.get('next_requirement')) is not int or not 1 <= b['next_requirement'] <= 478:
    parser.error('next_requirement must identify an original source-order requirement')
# Validate all existing structured recovery records before the first write.
for name in ['CURRENT_CHECKPOINT.json', 'VERIFICATION_REGISTER.json']:
    json.loads((workflow / name).read_text())
(workflow / 'IMPLEMENTATION_LOG.md').read_text()
ids = b.get('requirements')
if not isinstance(ids, list) or not ids or any(type(n) is not int or n < 1 or n > 478 for n in ids) or len(ids) != len(set(ids)):
    parser.error('requirements must be unique integer source-order IDs from 1 through 478')
verification = b.get('verification')
if not isinstance(verification, dict) or not isinstance(verification.get('executed'), dict) or any(not isinstance(verification.get(k), list) for k in ['not_run', 'remaining']):
    parser.error('verification must explicitly provide executed results, not_run tests and remaining requirements')
original = json.loads((workflow / 'MASTER_CHECKLIST.json').read_text())['requirements']
if len(original) != 478 or [r['sequence'] for r in original] != list(range(1, 479)):
    parser.error('original 478-item order must be intact before recording a batch')
now = datetime.datetime.now(datetime.timezone.utc).isoformat()
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
def save(p,d):
 tmp=p.with_suffix(p.suffix+'.tmp');tmp.write_text(json.dumps(d,indent=2)+'\n');tmp.replace(p)
p=workflow/'MASTER_CHECKLIST.json';d=json.loads(p.read_text())
for n in b['requirements']:
 row=d['requirements'][n-1]
 row.update(implementation_status='IN_PROGRESS',verification_status='SOURCE_REVIEWED',last_updated=now)
 for key,vals in [('relevant_source_files',b['files']),('related_tests',b['tests']),('evidence_of_implementation',[b['summary']])]:
  row[key]=list(dict.fromkeys(row[key]+vals))
 row['commit_reference']='batch:'+b['batch']+' (resolve containing commit with git log)'
 row['latest_batch_verification']={'batch': b['batch'], 'executed': verification['executed'], 'not_run': verification['not_run'], 'remaining': verification['remaining'], 'scope': 'Evidence for this batch only; does not certify the entire original requirement.'}
 row['remaining_verification_requirements']=verification['remaining']
save(p,d)
p=workflow/'CURRENT_CHECKPOINT.json';c=json.loads(p.read_text());c.update(current_HEAD=head,current_checklist_part=b.get('part',1),current_requirement=b['next_requirement'],current_implementation_batch=b['batch'],uncommitted_changes=sorted(set(subprocess.check_output(['git','diff','--name-only'],cwd=root,text=True).splitlines()+subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=root,text=True).splitlines())),next_exact_implementation_action=b['next'],updated_at=now,last_test_results=b['results'],last_executed_tests=b['commands'],last_batch_verification=verification);c['blocker_register']='development_workflow/BLOCKERS.md'; c['known_blockers']=['Research quarantine, full-source expansion and clinical/citation review remain open; see BLOCKERS.md','Production auth/cloud sync services are not configured; StoreKit source adapter awaits Apple SDK/receipt validation','Xcode/Apple SDK and iOS UI tests unavailable on Linux','MADLAD official weights/tokenizer blocked by huggingface.co proxy 403; domain draft immutable','Device/simulator llama.xcframework must be built on Mac; supplied framework is simulator-only','Both exact LifeBridge hosts excluded by enforced network policy; approved snapshots from both founder-specified sources absent','Canonical FAQ tulip not found in supplied assets','Clinical translation-quality and physical-device performance review not completed']; save(p,c)
p=workflow/'IMPLEMENTATION_LOG.md';p.write_text(p.read_text()+f"\n## {b['batch']}\n\n- Parent checkpoint: {head}.\n- Source-order requirements: {b['requirements']}.\n- Source files: {', '.join(b['files'])}.\n- {b['summary']}\n- Tests added/updated: {', '.join(b['tests'])}.\n- Verification: {json.dumps(b['results'])}.\n- Next action: {b['next']}\n- Commit: containing commit for batch {b['batch']}.\n")
(workflow/'RUN_LOGS'/ (b['batch']+'.json')).write_text(json.dumps({'timestamp':now,'commands':b['commands'],'results':b['results'],'verification':verification},indent=2)+'\n')
p=workflow/'VERIFICATION_REGISTER.json';d=json.loads(p.read_text());d.setdefault('batches',[]).append({'batch':b['batch'],'commands':b['commands'],'results':b['results'],'verification':verification,'timestamp':now});d['updated_at']=now;save(p,d)
