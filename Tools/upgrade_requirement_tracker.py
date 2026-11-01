#!/usr/bin/env python3
"""Separate implementation from verification without inventing uninspected states."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'Delivery/ImplementationTracker478.json';d=json.loads(p.read_text())
for r in d['requirements']:
 r.setdefault('beforeStatus',r['implementationStatus'])
 r.setdefault('historicalStatuses',[{'baseline':'verified November 1 continuation','status':r['beforeStatus']}])
 r['requirementDescription']=r['originalBreakdownItem']
 r['sourceSection']=r['prompt1BSection']
 states={'ALREADY IMPLEMENTED AND VERIFIED':'IMPLEMENTED','IMPLEMENTED BUT NOT VERIFIED':'IMPLEMENTED','PARTIALLY IMPLEMENTED':'PARTIALLY IMPLEMENTED','INCORRECTLY IMPLEMENTED':'PARTIALLY IMPLEMENTED','BLOCKED BY TECHNICAL DEPENDENCY':'BLOCKED'}
 r.setdefault('currentImplementationState',states.get(r['inspectionState']))
 r.setdefault('implementationAssessment','ASSESSED' if r['currentImplementationState'] else 'NOT ASSESSED: no claim of implemented or missing behavior')
 r.setdefault('verificationState',{'PASS':'PASS','FAIL':'FAIL','PARTIAL':'INCONCLUSIVE','NOT VERIFIED':'NOT TESTED','BLOCKED':'NOT TESTED'}[r['implementationStatus']])
 r['existingSourceFiles']=[f for f in r['relevantSourceFiles'] if (root/f).is_file()]
 r.setdefault('missingImplementation',None if r['currentImplementationState'] is None else r['remainingIssues'])
 r['dependencies']={'parts':r['dependsOnParts'],'specificBlockers':r['remainingIssues'] if r['implementationStatus']=='BLOCKED' else []}
 r.setdefault('requiredAcceptanceTests',[{'criterion':r['originalBreakdownItem'],'testIDs':[],'assessment':'Item-specific test mapping still required'}])
 r['evidenceReferences']=r['supportingEvidence']
 r['finalDisposition']=r['implementationStatus']
d['schemaVersion']=2
d['implementationStatePolicy']='IMPLEMENTED / PARTIALLY IMPLEMENTED / NOT IMPLEMENTED / BLOCKED. Null explicitly means not assessed; absence of verification is not evidence that a feature is missing.'
d['verificationStatePolicy']='PASS / FAIL / NOT TESTED / INCONCLUSIVE. Previous statuses are retained verbatim in beforeStatus and historicalStatuses.'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print('Preserved all 478 historical statuses; separated implementation, verification, and explicit assessment gaps.')
