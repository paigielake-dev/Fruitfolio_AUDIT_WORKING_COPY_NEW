#!/usr/bin/env python3
"""Populate Fruitfolio Localizable.xcstrings with a local llama.cpp CLI + FruitfolioAI.gguf.
No network/API use. Existing non-empty translations are preserved unless --overwrite is passed.
"""
import argparse, json, re, subprocess, sys, tempfile
from pathlib import Path

LANGUAGES = {
'am':'Amharic','ar':'Arabic','bi':'Bislama','bn':'Bengali','ch':'Chamorro','de':'German','es':'Spanish','fa':'Persian','fil':'Filipino','fj':'Fijian','fr':'French','gil':'Kiribati (Gilbertese)','gu':'Gujarati','ha':'Hausa','haw':'Hawaiian','hi':'Hindi','ig':'Igbo','it':'Italian','ja':'Japanese','kn':'Kannada','ko':'Korean','mh':'Marshallese','mi':'Māori','ml':'Malayalam','mr':'Marathi','niu':'Niuean','pa':'Punjabi','pau':'Palauan','pt':'Portuguese','rar':'Cook Islands Māori','sm':'Samoan','sw':'Swahili','ta':'Tamil','te':'Telugu','to':'Tongan','tpi':'Tok Pisin','tvl':'Tuvaluan','ty':'Tahitian','ur':'Urdu','vi':'Vietnamese','yo':'Yoruba','zh-Hans':'Simplified Chinese','zh-Hant':'Traditional Chinese','zu':'Zulu'
}
TOKEN_RE = re.compile(r'%(?:\d+\$)?[@a-zA-Z]|\\\([^)]*\)|https?://\S+|\b[A-Z]{2,}\b|\b\d+(?:\.\d+)?(?:%|°[CF]|mg|g|kg|mL|L|cm|mm)?\b')

def mask(text):
    vals=[]
    def repl(m): vals.append(m.group(0)); return f'⟦KEEP_{len(vals)-1}⟧'
    return TOKEN_RE.sub(repl,text), vals

def unmask(text, vals):
    for i,v in enumerate(vals): text=text.replace(f'⟦KEEP_{i}⟧',v)
    return text

def translate(cli, model, source, language):
    masked, vals=mask(source)
    prompt=(f'Translate the following Fruitfolio user-interface text from English into {language}. '
            'Preserve meaning exactly. Preserve negation, uncertainty (may/can/estimated/predicted), numbers, units, citations, and every ⟦KEEP_n⟧ token exactly. '
            'Do not explain. Do not add quotation marks. Output only the translation.\n\nEnglish: '+masked+'\nTranslation:')
    cmd=[str(cli),'-m',str(model),'-p',prompt,'-n','256','--temp','0.1','--no-display-prompt']
    r=subprocess.run(cmd,capture_output=True,text=True)
    if r.returncode: raise RuntimeError(r.stderr.strip() or f'llama exit {r.returncode}')
    out=r.stdout.strip().splitlines()
    out=out[-1].strip() if out else ''
    out=unmask(out,vals).strip().strip('"')
    if not out: raise RuntimeError('empty translation')
    for v in vals:
        if v not in out: raise RuntimeError(f'protected token changed or missing: {v}')
    return out

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--catalog',required=True,type=Path); ap.add_argument('--model',required=True,type=Path); ap.add_argument('--llama-cli',required=True,type=Path); ap.add_argument('--overwrite',action='store_true'); ap.add_argument('--limit',type=int)
    a=ap.parse_args(); data=json.loads(a.catalog.read_text()); failures=[]; done=0
    for key,entry in data.get('strings',{}).items():
        source=entry.get('localizations',{}).get('en',{}).get('stringUnit',{}).get('value') or key
        if not source.strip(): continue
        locs=entry.setdefault('localizations',{})
        for code,name in LANGUAGES.items():
            unit=locs.setdefault(code,{}).setdefault('stringUnit',{'state':'new','value':''})
            if unit.get('value') and not a.overwrite: continue
            try:
                unit['value']=translate(a.llama_cli,a.model,source,name); unit['state']='translated'; done+=1
                print(f'[{done}] {code}: {source[:55]}')
            except Exception as e:
                failures.append({'key':key,'locale':code,'error':str(e)}); print(f'FAIL {code} {key[:40]}: {e}',file=sys.stderr)
            if a.limit and done>=a.limit: break
        if a.limit and done>=a.limit: break
        a.catalog.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    a.catalog.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    report=a.catalog.with_name('LOCALIZATION_LLAMA_FAILURES.json'); report.write_text(json.dumps(failures,ensure_ascii=False,indent=2)+'\n')
    print(f'Completed {done}; failures {len(failures)}; report {report}')
if __name__=='__main__':
    raise SystemExit('Inactive legacy investigation: FruitfolioAI must not substitute for approved MADLAD translation. No catalog changes were made.')
