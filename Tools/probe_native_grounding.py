#!/usr/bin/env python3
"""Real local GGUF regression probe. Does not claim iOS/clinical acceptance."""
import argparse,json,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--runtime',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1]
s=(root/'Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift').read_text()
template=s[s.index('nonisolated enum FruitfolioEvidencePromptBuilder'):].split('return """',1)[1].split('"""',1)[0]
template='\n'.join(line[8:] if line.startswith('        ') else line for line in template.strip('\n').splitlines())
grammar=s.split('private static let draftGrammar = #"""',1)[1].split('"""#',1)[0]
out=root/'Fruitfolio_Verification_Evidence/Continuation/Grounding';out.mkdir(parents=True,exist_ok=True)
fixtures=[('positive','How does progesterone affect basal body temperature?','note_1','progesterone and temperature','Progesterone is associated with a post-ovulatory rise in basal body temperature.'),('negation','Does a single temperature rise confirm ovulation?','negative_note_2','temperature rise confirm ovulation','A single temperature rise does not confirm ovulation.')]
results=[]
for name,question,eid,claim,text in fixtures:
 substitutions={'question':question,'claimMapText':f'[CLAIM claim_0] {claim}\nPERMITTED EVIDENCE IDS: {eid}','noteText':f'[NOTE {eid}]\n{text}','sourceText.isEmpty ? "No additional source extracts." : sourceText':'No additional source extracts.','evidence.safetyClassification.level.rawValue':'normal','trackerContext':'[none supplied]'}
 prompt=template
 for key,value in substitutions.items():prompt=prompt.replace('\\('+key+')',value)
 assert '\\(' not in prompt
 prompt='<|im_start|>system\nYou are the local Fruitfolio synthesis engine. Follow the supplied instructions exactly. Output only the requested JSON object and nothing before or after it.<|im_end|>\n<|im_start|>user\n'+prompt+'<|im_end|>\n<|im_start|>assistant\n'
 pf=out/(name+'.prompt.txt');pf.write_text(prompt)
 gf=out/(name+'.gbnf');gf.write_text(grammar+'\nevidence-id ::= '+json.dumps(json.dumps(eid))+' ws\n')
 args=[str(a.runtime),'--model',str(root/'FruitfolioAI.gguf'),'--no-conversation','--no-display-prompt','--no-warmup','--temp','0','-t','4','-ngl','0','-c','4096','-n','768','--grammar-file',str(gf),'-f',str(pf)]
 r=subprocess.run(args,capture_output=True,text=True,timeout=180)
 (out/(name+'.stdout.txt')).write_text(r.stdout);(out/(name+'.stderr.txt')).write_text(r.stderr)
 draft=None;error=None
 try:
  stdout=re.sub(r'\x1b\[[0-9;]*[A-Za-z]','',r.stdout)
  draft=json.JSONDecoder().raw_decode(stdout[stdout.index('{'):])[0]
  assert r.returncode==0
  assert draft['bridge'] is None and draft['limitation'] is None
  assert draft['claims']
  for c in draft['claims']:
   assert ' '.join(c['text'].split())==' '.join(text.split()),'claim text differs from complete supplied evidence'
   assert c['evidenceIDs']==[eid],'evidence ID differs'
 except (AssertionError,ValueError,KeyError) as e:error=str(e) or type(e).__name__
 results.append({'fixture':name,'result':'FAIL' if error else 'PASS','scope':'Linux native GGUF; not iOS or independent clinical validation','return_code':r.returncode,'draft':draft,'error':error})
(out/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(json.dumps(results,ensure_ascii=False,indent=2))
raise SystemExit(any(x['result']=='FAIL' for x in results))
