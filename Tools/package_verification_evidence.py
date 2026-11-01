#!/usr/bin/env python3
"""Preserve all CI evidence in connector-downloadable parts without omissions."""
import hashlib, json, zipfile
from pathlib import Path
root=Path('Fruitfolio_Verification_Evidence')
out=Path('VerificationDownloads');out.mkdir(exist_ok=True)
archive=out/'Fruitfolio_Verification_Evidence.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file():z.write(p,p.as_posix())
assert zipfile.ZipFile(archive).testzip() is None
parts=[]
with archive.open('rb') as stream:
    for n in range(1,9):
        data=stream.read(400*1024*1024)
        if not data:break
        p=out/f'{archive.name}.part{n:02}'
        p.write_bytes(data)
        parts.append({'name':p.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
    assert not stream.read(1),'Evidence exceeds eight parts; expand upload slots without omitting files.'
manifest={'archive':archive.name,'archiveSHA256':hashlib.file_digest(archive.open('rb'),'sha256').hexdigest(),'parts':parts,'reconstruction':'Concatenate part01, part02, ... in numeric order, verify archiveSHA256, then unzip. These are CI evidence only, not the completed application.'}
(out/'EvidenceParts.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest,indent=2))
