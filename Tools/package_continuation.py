#!/usr/bin/env python3
"""Package real continuation work without claiming final application acceptance."""
import hashlib,json,shutil,zipfile,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root.parent/'deliverables';out.mkdir(exist_ok=True)
archive=out/'Fruitfolio_Prompt_1B_CONTINUATION_2026-11-01.zip'
excluded={'.git','__pycache__','.ciDerivedData','DerivedData','.build-apple-runtime','target','VerificationDownloads'}
files=[]
for p in sorted(root.rglob('*')):
 rel=p.relative_to(root)
 if any(x in excluded for x in rel.parts) or p.name=='.DS_Store' or p.suffix=='.pyc':continue
 if re.match(r'^\..*\.(?:gguf|pdf|mp4|png|wav|mp3|docx|zip)\.[A-Za-z0-9]{4,}(?:\..*)?$',p.name):continue
 if p.is_file() and rel.as_posix()!='Delivery/CONTINUATION_ARCHIVE_FILES.json':files.append((p,rel.as_posix()))
required=['Fruitfolio.xcodeproj/project.pbxproj','FruitfolioAI.gguf','Models/MADLAD/model-q4k.gguf','Models/MADLAD/tokenizer.json','Models/MADLAD/spiece.model','Vendor/llama.xcframework/Info.plist','Fruitfolio/FruitfolioResearchPackage.json','Delivery/ImplementationTracker478.json']
assert set(required)<={rel for _,rel in files}
manifest={'deliveryStatus':'INCOMPLETE CONTINUATION — NOT FINAL_COMPLETE','sourceCommit':'4d480ed949a6e50b70a8c08d3b2a47b65b89652d','checkpointSHA256':'4e44c9d57978a2109980d13962d169611eadb1bcd71eed81818fe3683a599ec3','files':[]}
for p,rel in files:
 manifest['files'].append({'path':rel,'bytes':p.stat().st_size,'sha256':hashlib.file_digest(p.open('rb'),'sha256').hexdigest()})
(root/'Delivery/CONTINUATION_ARCHIVE_FILES.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
files=[(p,r) for p,r in files if r!='Delivery/CONTINUATION_ARCHIVE_FILES.json']
files.append((root/'Delivery/CONTINUATION_ARCHIVE_FILES.json','Delivery/CONTINUATION_ARCHIVE_FILES.json'))
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True) as z:
 for p,rel in files:z.write(p,rel)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 names=z.namelist();assert len(names)==len(set(names))
 for item in manifest['files']:
  if item['path']=='Delivery/CONTINUATION_ARCHIVE_FILES.json':continue
  with z.open(item['path']) as stream:assert hashlib.file_digest(stream,'sha256').hexdigest()==item['sha256'],item['path']
 assert all(not Path(n).is_absolute() and '..' not in Path(n).parts for n in names)
parts=[]
with archive.open('rb') as stream:
 n=1
 while data:=stream.read(400*1024*1024):
  p=out/f'{archive.name}.part{n:02}';p.write_bytes(data)
  parts.append({'name':p.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()});n+=1
index={'archive':archive.name,'status':manifest['deliveryStatus'],'bytes':archive.stat().st_size,'sha256':hashlib.file_digest(archive.open('rb'),'sha256').hexdigest(),'files':len(files),'parts':parts}
(out/'Fruitfolio_Continuation_Parts.json').write_text(json.dumps(index,indent=2)+'\n')
(out/'Fruitfolio_Continuation_SHA256SUMS.txt').write_text(''.join(x['sha256']+'  '+x['name']+'\n' for x in parts)+index['sha256']+'  '+archive.name+'\n')
(out/'Reconstruct_Fruitfolio_Continuation.py').write_text('''from pathlib import Path
import hashlib,json,zipfile
root=Path(__file__).resolve().parent
index=json.loads((root/'Fruitfolio_Continuation_Parts.json').read_text())
archive=root/index['archive']
with archive.open('wb') as output:
 for item in index['parts']:
  p=root/item['name']
  assert p.stat().st_size==item['bytes'],p
  assert hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==item['sha256'],p
  with p.open('rb') as stream:
   while chunk:=stream.read(8*1024*1024):output.write(chunk)
assert hashlib.file_digest(archive.open('rb'),'sha256').hexdigest()==index['sha256']
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print('Archive verified:',archive)
print('Extract the ZIP, then open Fruitfolio.xcodeproj on an Apple Silicon Mac.')
print('This is an incomplete implementation continuation, not final acceptance.')
''')
print(json.dumps(index,indent=2),flush=True)
