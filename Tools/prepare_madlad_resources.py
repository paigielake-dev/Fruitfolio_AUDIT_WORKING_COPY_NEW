#!/usr/bin/env python3
"""Acquire only approved official resources, checking every pinned SHA-256."""
from pathlib import Path
import hashlib,json,urllib.request,os
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'TranslationInvestigation/approved-madlad-resources.json').read_text())
out=root/'Models/MADLAD';out.mkdir(parents=True,exist_ok=True)
for item in manifest:
 name=item['file'];p=out/name
 assert Path(name).name==name
 expected=item['sha256']
 if p.is_file() and p.stat().st_size==item['size_bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==expected:
  print('Verified existing',name,flush=True);continue
 temp=out/(name+'.download')
 url='https://huggingface.co/google/madlad400-3b-mt/resolve/main/'+name
 with urllib.request.urlopen(url,timeout=120) as source,temp.open('wb') as sink:
  while chunk:=source.read(8*1024*1024):sink.write(chunk)
 if temp.stat().st_size!=item['size_bytes'] or hashlib.file_digest(temp.open('rb'),'sha256').hexdigest()!=expected:
  temp.unlink(missing_ok=True);raise SystemExit('Official resource integrity check failed: '+name)
 os.replace(temp,p);print('Retrieved and verified',name,flush=True)
