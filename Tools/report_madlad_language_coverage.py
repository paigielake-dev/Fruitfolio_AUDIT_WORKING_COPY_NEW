#!/usr/bin/env python3
"""Report exact model tags and actual fixture results, without inventing aliases."""
import json,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
tokenizer=json.loads((root/'Models/MADLAD/tokenizer.json').read_text())
vocab=tokenizer['model']['vocab']
if isinstance(vocab,list): tokens={row[0] for row in vocab}
else: tokens=set(vocab)
tokens.update(row['content'] for row in tokenizer.get('added_tokens',[]))
languages=re.findall(r'case (\w+) = "([^"]+)"',(root/'Fruitfolio/Core/AppArchitecture/SettingsStore.swift').read_text().split('var id:')[0])
coverage=[]
for name,locale in languages:
 tag='<2'+('zh' if locale.startswith('zh-') else locale)+'>'
 coverage.append({'selection':name,'locale':locale,'exactTargetTag':tag,'tagPresent':tag in tokens,'qualityStatus':'NOT VERIFIED','scriptDistinction':'NOT VERIFIED' if locale.startswith('zh-') else None})
p=root/'Fruitfolio_Verification_Evidence/MADLAD'
rows=[json.loads(line) for line in (p/'extended-sentence-results.jsonl').read_text().splitlines()]
measurements=[{'prompt':r['prompt'],'output':r['output'],'exactNumericAndUnitPreservation':'PASS' if '2.5 ng/mL' in r['output'] else 'FAIL'} for r in rows if '2.5 ng/mL' in r['prompt']]
report={'scope':'Exact official tokenizer inventory and actual Linux CPU sentence fixtures; not clinical or iPhone approval',
 'requiredSelections':len(coverage),'coverage':coverage,'missingExactTags':[r['locale'] for r in coverage if not r['tagPresent']],
 'executedFixtures':len(rows),'allReachedEOS':all(r['reached_eos'] for r in rows),'measurements':measurements,
 'rawParagraphStatus':'FAIL: source identifiers and safety statement altered; retained original evidence',
 'productionStatus':'DISABLED pending safe structured preservation, required-language quality and actual Apple/physical-device runtime acceptance',
 'limitations':['Exact-tag absence is not proof that a documented official alias does not exist; no alias has been invented.',
 'Chinese script selections share zh; distinct requested script behavior remains unverified.',
 'Sentence examples are developer diagnostics, not independent medically qualified translation review.',
 'No full app-wide localization or arbitrary-claim translation acceptance follows from these fixtures.']}
(p/'language-coverage-and-extended-fixtures.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'requiredSelections':len(coverage),'missingExactTags':report['missingExactTags'],'executedFixtures':len(rows),'allReachedEOS':report['allReachedEOS'],'measurements':measurements},ensure_ascii=False,indent=2))
