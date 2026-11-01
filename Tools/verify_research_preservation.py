#!/usr/bin/env python3
"""Compare imported evidence against the authoritative checkpoint, without rewriting it."""
import json, subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
old=json.loads(subprocess.check_output(['git','show','b2ce3aa402435d864b20b9742216229deec03b8c:Fruitfolio/FruitfolioResearchPackage.json'],cwd=root))
new=json.loads((root/'Fruitfolio/FruitfolioResearchPackage.json').read_text())
a={x['chunkID']:x for x in old['researchNoteChunks']};b={x['chunkID']:x for x in new['researchNoteChunks']}
checks={
 'noteIDsPreserved':a.keys()==b.keys(),
 'allNoteTextPreserved':all(b[k]['text']==v['text'] for k,v in a.items()),
 'allBibliographyAssociationsPreserved':all(b[k]['relatedSourceIDs']==v['sourceIDs'] for k,v in a.items()),
 'guideChunksUnchanged':old['sourceChunks']==new['sourceChunks'],
 'allOriginalSourceIDsRetained':{x['sourceID'] for x in old['sources']} <= {x['sourceID'] for x in new['sources']},
 'onlyActualDocumentsEligible':sum(x['retrievalEligibility'] for x in new['sources'])==2,
 'noPaperRecordIncorrectlyEligible':all(not x['retrievalEligibility'] for x in new['sources'] if x['sourceID'].startswith('ref_')),
}
report={'scope':'Data preservation and attribution only; not clinical truth or primary-paper verification','baseline':'b2ce3aa402435d864b20b9742216229deec03b8c','checks':{k:'PASS' if v else 'FAIL' for k,v in checks.items()}}
out=root/'Fruitfolio_Verification_Evidence/Research';out.mkdir(parents=True,exist_ok=True)
(out/'attribution-preservation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
assert all(checks.values())
