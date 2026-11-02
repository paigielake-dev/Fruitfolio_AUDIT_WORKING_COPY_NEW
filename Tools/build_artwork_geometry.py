#!/usr/bin/env python3
"""Measure existing PNGs without changing artwork or choosing screen assignments."""
import hashlib,json
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
assets={}
for contents in sorted((root/'Fruitfolio/Assets.xcassets').rglob('Contents.json')):
    data=json.loads(contents.read_text())
    for item in data.get('images',[]):
        if not item.get('filename','').lower().endswith('.png'):continue
        p=contents.parent/item['filename']
        with Image.open(p) as image:
            width,height=image.size
            alpha=image.getchannel('A') if 'A' in image.getbands() else None
            bounds=alpha.getbbox() if alpha else (0,0,width,height)
        name=contents.parent.stem
        value={'width':width,'height':height,'visibleBounds':list(bounds) if bounds else None,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':str(p.relative_to(root))}
        # Prefer the 1x/universal member; duplicate scales never change selection.
        if name not in assets or item.get('scale')=='1x':assets[name]=value
out=root/'Fruitfolio/ArtworkGeometry.json'
out.write_text(json.dumps({'schemaVersion':1,'measurement':'Original PNG alpha > 0; no artwork modified','assets':assets},ensure_ascii=False,indent=2)+'\n')
print('Measured',len(assets),'original image sets')
