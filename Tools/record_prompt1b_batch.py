#!/usr/bin/env python3
"""Record one verified local batch without promoting whole-requirement status.

Each manifest must explicitly distinguish executed, unexecuted and remaining
verification. Original checklist identity/text/order and unrelated rows remain.
"""
import argparse, json, subprocess, datetime, re, importlib.util, sys
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
    document = json.loads((workflow / name).read_text())
    if not isinstance(document, dict):
        parser.error(name + ' must remain a structured object before any recovery record changes')
    if name == 'VERIFICATION_REGISTER.json' and not isinstance(document.get('batches', []), list):
        parser.error('verification batches must remain a list before any recovery record changes')
if not (workflow / 'RUN_LOGS').is_dir():
    parser.error('RUN_LOGS must exist before any recovery record changes')
(workflow / 'IMPLEMENTATION_LOG.md').read_text()
ids = b.get('requirements')
if not isinstance(ids, list) or not ids or any(type(n) is not int or n < 1 or n > 478 for n in ids) or len(ids) != len(set(ids)):
    parser.error('requirements must be unique integer source-order IDs from 1 through 478')
def valid_verification(value):
    return isinstance(value, dict) and isinstance(value.get('executed'), dict) and all(
        isinstance(value.get(key), list) and all(isinstance(item, str) for item in value[key])
        for key in ['not_run', 'remaining'])

verification = b.get('verification')
if not valid_verification(verification):
    parser.error('verification must explicitly provide executed results, not_run tests and remaining requirements')
entries = b.get('entry_evidence', {})
if not isinstance(entries, dict):
    parser.error('entry_evidence must be an object keyed by targeted source-order IDs')
for entry_id, entry in entries.items():
    if entry_id not in {str(n) for n in ids} or not isinstance(entry, dict):
        parser.error("entry evidence may refer only to this batch's targeted requirement IDs")
    if not isinstance(entry.get('summary'), str) or any(not isinstance(entry.get(k), list) or not all(isinstance(x, str) for x in entry[k]) for k in ['files', 'tests']):
        parser.error('each entry must explicitly identify its implementation evidence, source files and tests')
    ev = entry.get('verification')
    if not valid_verification(ev):
        parser.error('each entry must distinguish executed, unexecuted and remaining verification')
# Founder additions are separate source identities; never renumber them into 478.
supplemental_ids = b.get('supplemental_requirements', [])
if not isinstance(supplemental_ids, list) or not all(isinstance(value, str) for value in supplemental_ids) or len(supplemental_ids) != len(set(supplemental_ids)):
    parser.error('supplemental_requirements must be unique exact founder IDs')
supplemental_entries = b.get('supplemental_entry_evidence', {})
if not isinstance(supplemental_entries, dict):
    parser.error('supplemental_entry_evidence must be an object')
for entry_id, entry in supplemental_entries.items():
    if entry_id not in supplemental_ids or not isinstance(entry, dict):
        parser.error('supplemental evidence may refer only to targeted founder IDs')
    if not isinstance(entry.get('summary'), str) or any(not isinstance(entry.get(k), list) or not all(isinstance(value, str) for value in entry[k]) for k in ['files', 'tests']):
        parser.error('supplemental entry evidence must identify source, tests and implementation')
    ev = entry.get('verification')
    if not valid_verification(ev):
        parser.error('supplemental entries must distinguish executed, unexecuted and remaining verification')
supplemental = None
if supplemental_ids:
    supplemental_path = workflow / 'SUPPLEMENTAL_SPEC_CHECKLIST.json'
    if not supplemental_path.is_file():
        parser.error('the exact founder index must exist before recording supplemental evidence')
    supplemental = json.loads(supplemental_path.read_text())
    source_name = supplemental.get('source')
    if not isinstance(source_name, str) or Path(source_name).is_absolute():
        parser.error('supplemental source must remain inside the repository')
    source_path = (root / source_name).resolve()
    if not source_path.is_relative_to(root) or not source_path.is_file():
        parser.error('supplemental source must remain readable inside the repository')
    spec = importlib.util.spec_from_file_location('fruitfolio_supplemental_source', Path(__file__).with_name('sync_supplemental_spec.py'))
    source_module = importlib.util.module_from_spec(spec)
    previous_bytecode_policy = sys.dont_write_bytecode
    try:
        sys.dont_write_bytecode = True
        spec.loader.exec_module(source_module)
    finally:
        sys.dont_write_bytecode = previous_bytecode_policy
    expected_hash, expected_rows = source_module.specifications(source_path)
    stored_rows = supplemental.get('requirements')
    if supplemental.get('source_sha256') != expected_hash or not isinstance(stored_rows, list) or len(stored_rows) != len(expected_rows):
        parser.error('supplemental source identity must remain exact before recording evidence')
    for expected, stored in zip(expected_rows, stored_rows):
        if not isinstance(stored, dict) or any(stored.get(key) != value for key, value in expected.items()):
            parser.error('supplemental descriptions, hashes, IDs and original order must remain exact')
    known = {row['id'] for row in stored_rows}
    if any(identifier not in known for identifier in supplemental_ids):
        parser.error('unknown supplemental founder ID')
    for row in stored_rows:
        if row['id'] in supplemental_ids:
            for key in ['relevant_source_files', 'related_tests', 'evidence']:
                if not isinstance(row.get(key, []), list) or not all(isinstance(value, str) for value in row.get(key, [])):
                    parser.error('supplemental source/test/evidence collections must remain string lists')
            if not isinstance(row.get('batch_evidence', []), list):
                parser.error('supplemental batch evidence must remain a list')
original = json.loads((workflow / 'MASTER_CHECKLIST.json').read_text())['requirements']
if len(original) != 478 or [r['sequence'] for r in original] != list(range(1, 479)):
    parser.error('original 478-item order must be intact before recording a batch')
next_section = original[b['next_requirement'] - 1].get('original_checklist_part')
next_section_match = re.match(r'^Part (\d+)\b', next_section) if isinstance(next_section, str) else None
if next_section_match is None or not 1 <= int(next_section_match.group(1)) <= 10:
    parser.error('the next original requirement must identify its checklist section before recovery records can change')
next_part = int(next_section_match.group(1))
now = datetime.datetime.now(datetime.timezone.utc).isoformat()
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
def save(p,d):
 tmp=p.with_suffix(p.suffix+'.tmp');tmp.write_text(json.dumps(d,indent=2)+'\n');tmp.replace(p)
p=workflow/'MASTER_CHECKLIST.json';d=json.loads(p.read_text())
for n in b['requirements']:
 row=d['requirements'][n-1]
 entry=entries.get(str(n), {})
 row_verification=entry.get('verification', verification)
 if row.get('implementation_status') != 'BLOCKED':
  row.update(implementation_status='IN_PROGRESS',verification_status='SOURCE_REVIEWED')
 row['last_updated']=now
 for key,vals in [('relevant_source_files',entry.get('files', b['files'])),('related_tests',entry.get('tests', b['tests'])),('evidence_of_implementation',[entry.get('summary', b['summary'])])]:
  row[key]=list(dict.fromkeys(row[key]+vals))
 row['commit_reference']='batch:'+b['batch']+' (resolve containing commit with git log)'
 row['latest_batch_verification']={'batch': b['batch'], 'executed': row_verification['executed'], 'not_run': row_verification['not_run'], 'remaining': row_verification['remaining'], 'scope': 'Evidence for this batch only; does not certify the entire original requirement.'}
 row['remaining_verification_requirements']=row_verification['remaining']
save(p,d)
if supplemental is not None:
 for row in supplemental['requirements']:
  if row['id'] not in supplemental_ids: continue
  entry = supplemental_entries.get(row['id'], {})
  row_verification = entry.get('verification', verification)
  source_files, tests = entry.get('files', b['files']), entry.get('tests', b['tests'])
  summary = entry.get('summary', b['summary'])
  for key, values in [('relevant_source_files', source_files), ('related_tests', tests), ('evidence', [summary])]:
   row[key] = list(dict.fromkeys(row.get(key, []) + values))
  if row.get('implementation_status') == 'NOT_STARTED':
   row.update(implementation_status='IN_PROGRESS', verification_status='SOURCE_REVIEWED')
  row['latest_batch_verification'] = {'batch': b['batch'], **row_verification,
      'scope': 'Evidence for this batch only; whole founder acceptance and blockers remain separate.'}
  row['remaining_verification_requirements'] = row_verification['remaining']
  row['commit_reference'] = 'batch:' + b['batch'] + ' (resolve containing commit with git log)'
  row['last_updated'] = now
  row.setdefault('batch_evidence', []).append({'batch': b['batch'], 'implementation_evidence': summary,
      'files': source_files, 'tests': tests, 'verification': row_verification, 'parent_checkpoint': head})
 save(workflow / 'SUPPLEMENTAL_SPEC_CHECKLIST.json', supplemental)
p=workflow/'CURRENT_CHECKPOINT.json';c=json.loads(p.read_text());c.update(current_HEAD=head,current_checklist_part=next_part,current_checklist_section=next_section,last_recorded_batch_part=b.get('part',next_part),current_requirement=b['next_requirement'],current_implementation_batch=b['batch'],uncommitted_changes=sorted(set(subprocess.check_output(['git','diff','--name-only'],cwd=root,text=True).splitlines()+subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=root,text=True).splitlines())),next_exact_implementation_action=b['next'],updated_at=now,last_test_results=b['results'],last_executed_tests=b['commands'],last_batch_verification=verification,last_supplemental_requirements=supplemental_ids);c['blocker_register']='development_workflow/BLOCKERS.md'; c['known_blockers']=['Research quarantine, full-source expansion and clinical/citation review remain open; see BLOCKERS.md','Production auth/cloud sync services are not configured; StoreKit source adapter awaits Apple SDK/receipt validation','Xcode/Apple SDK and iOS UI tests unavailable on Linux','MADLAD official weights/tokenizer blocked by huggingface.co proxy 403; domain draft immutable','Device/simulator llama.xcframework must be built on Mac; supplied framework is simulator-only','Both exact LifeBridge hosts excluded by enforced network policy; approved snapshots from both founder-specified sources absent','Canonical FAQ tulip not found in supplied assets','Clinical translation-quality and physical-device performance review not completed']; save(p,c)
p=workflow/'IMPLEMENTATION_LOG.md';p.write_text(p.read_text()+f"\n## {b['batch']}\n\n- Parent checkpoint: {head}.\n- Source-order requirements: {b['requirements']}.\n- Separate founder additions: {supplemental_ids}.\n- Source files: {', '.join(b['files'])}.\n- {b['summary']}\n- Tests added/updated: {', '.join(b['tests'])}.\n- Verification: {json.dumps(b['results'])}.\n- Next action: {b['next']}\n- Commit: containing commit for batch {b['batch']}.\n")
(workflow/'RUN_LOGS'/ (b['batch']+'.json')).write_text(json.dumps({'timestamp':now,'requirements':ids,'supplemental_requirements':supplemental_ids,'commands':b['commands'],'results':b['results'],'verification':verification},indent=2)+'\n')
p=workflow/'VERIFICATION_REGISTER.json';d=json.loads(p.read_text());d.setdefault('batches',[]).append({'batch':b['batch'],'requirements':ids,'supplemental_requirements':supplemental_ids,'commands':b['commands'],'results':b['results'],'verification':verification,'timestamp':now});d['updated_at']=now;save(p,d)
