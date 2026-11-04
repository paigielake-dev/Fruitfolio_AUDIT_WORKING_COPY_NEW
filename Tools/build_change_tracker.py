#!/usr/bin/env python3
"""Lossless founder checklist import. Existing assessments survive regeneration."""
import collections, hashlib, json, re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Specification/Fruitfolio_Prompt_1B_Change_Breakdown_478.md'
OUT = ROOT / 'Delivery/ImplementationTracker478.json'
HEADINGS = ['Universal blur system','Universal button system','Universal popup layout system','Universal decorative artwork layout system','Universal semantic text stylization','Performance and responsiveness']
PART_PATHS = {1:['Fruitfolio/Core/DesignSystems','Fruitfolio/Fruit Popup Engine','Fruitfolio/Hub/CutePopButtonStyle.swift'],2:['Fruitfolio/Introduction','Fruitfolio/Hub'],3:['Fruitfolio/Ask','Fruitfolio/Core/Intelligence'],4:['Fruitfolio/Saved Library','Fruitfolio/Guide Builder'],5:['Fruitfolio/Settings','Fruitfolio/Account','Fruitfolio/Cycle Tracker'],6:['Fruitfolio/Cycle Tracker'],7:['Fruitfolio/Fruit Basket'],8:['Fruitfolio/FAQ','Fruitfolio/Contact'],9:['Fruitfolio/Core/Localization','Models/MADLAD','TranslationInvestigation'],10:['FruitfolioTests','FruitfolioUITests','.github/workflows/ios-verification.yml']}
ANCHORS={1:'Universal rules, blur/popup/artwork and semantic styling (extracted lines 497–1208)',2:'Launch/Introduction and Hub (1216–1347)',3:'Ask the Encyclopedia and research grounding (1348–1705)',4:'My Encyclopedias and Build Your Own Guide (1706–1940)',5:'Settings/Account (1941 onward); 4.9 Hormone Information; 4.9.8 Hormone Rhythm',6:'Cycle Tracker and LifeBridge (2196–2707)',7:'Fruit Basket and Atlas 19N/19U (2708–2919)',8:'FAQ/Contact (2920 onward); universal visual rules',9:'7.9 Localization/MADLAD (252–410)',10:'Acceptance criteria throughout complete Prompt 1B'}
old = {r['requirementID']:r for r in json.loads(OUT.read_text())['requirements']} if OUT.exists() else {}
items=[]; part=0; section=''
for line_no,line in enumerate(SOURCE.read_text().splitlines(),1):
    m=re.match(r'Part (\d+) — (.+)',line)
    if m: part=int(m[1]); section=m[2]; continue
    if re.match(r'\d+[A-Z]\. ',line): section=line; continue
    m=re.match(r'(\d+)\\\.\s+(.+)',line)
    if not m or not part: continue
    if part==1 and m[2] in HEADINGS: section=m[2]; continue
    key=f'FF1B-{len(items)+1:03d}'
    candidates=[]
    for prefix in PART_PATHS[part]:
        p=ROOT/prefix
        if p.is_file(): candidates.append(prefix)
        elif p.is_dir(): pass  # Scope is recorded separately; do not imply item-level inspection.
    item={'requirementID':key,'part':part,'subsection':section,'originalNumber':int(m[1]),'originalBreakdownItem':m[2],'originalReference':f'Part {part} / {section} / {m[1]}','sourceLine':line_no,'prompt1BSection':{'candidateSection':ANCHORS[part],'exactCrossReferenceStatus':'PENDING: confirm against full authoritative specification'},'relevantSourceFiles':candidates,'candidateSourceScopes':PART_PATHS[part],'sourceMappingStatus':'Candidate feature scope; item-level inspection pending','implementationStatus':'NOT VERIFIED','inspectionState':'PENDING BASELINE INSPECTION','changesMade':[],'testsPerformed':[],'testResults':[],'supportingEvidence':[],'remainingIssues':['Item-level checkpoint assessment and requirement-specific runtime verification pending.'],'dependsOnParts':list(range(1,part))}
    if key in old:
        prior=old[key]
        assert prior['originalBreakdownItem']==item['originalBreakdownItem'],key
        for field in ['implementationStatus','inspectionState','changesMade','testsPerformed','testResults','supportingEvidence','remainingIssues','sourceMappingStatus','relevantSourceFiles']: item[field]=prior[field]
    items.append(item)
counts=dict(collections.Counter(r['part'] for r in items))
assert counts=={1:70,2:25,3:74,4:52,5:59,6:39,7:53,8:18,9:52,10:36},counts
assert len(items)==478
result={'schemaVersion':1,'completionClaim':False,'checkpointCommit':'b2ce3aa402435d864b20b9742216229deec03b8c','source':str(SOURCE.relative_to(ROOT)),'sourceSHA256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'statusPolicy':'PASS requires implementation plus sufficient evidence. NOT VERIFIED with PENDING inspection makes no implementation-existence claim; provisional intake status only. Candidate source files and Prompt references require item-level confirmation.','partCounts':counts,'requirements':items}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(f'Imported {len(items)} exact items; part counts {counts}; existing assessments preserved.')
