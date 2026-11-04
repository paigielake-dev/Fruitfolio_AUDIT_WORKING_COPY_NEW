#!/usr/bin/env python3
"""Recover unchanged human-readable/visual exports from the oversized first sprint artifact.
No tests are rerun and no original evidence is removed or relabeled.
"""
import argparse, hashlib, json, os, shutil, urllib.request, zipfile
from pathlib import Path, PurePosixPath
from recover_run93_accessibility_exports import NoCredentialRedirect, request, REPO

ORIGINALS = {
    2: (13148295738, 41449196626, '624d7a5b532e91f1d52f31eafa2d96322f60e35a', '1cd298572cf8a506b67b6cd397db5ed4ae13c0cb89bf3384c179229685e46806'),
    9: (13150184646, 41457994650, 'aee406f335dafdd2fa2d0fa01c1e3c0fc6d7319a', 'e65dfcdbe6aa6d3c278a52f4f4ad6bbaa13b1be076546258434817b673691387')
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run_number', type=int, choices=sorted(ORIGINALS), nargs='?', default=2)
    number = parser.parse_args().run_number
    ARTIFACT, RUN, COMMIT, SHA256 = ORIGINALS[number]
    assert os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('GITHUB_REPOSITORY') == REPO
    opener = urllib.request.build_opener(NoCredentialRedirect())
    with opener.open(request(f'/actions/artifacts/{ARTIFACT}'), timeout=30) as response:
        metadata = json.load(response)
    assert metadata['workflow_run']['id'] == RUN and metadata['workflow_run']['head_sha'] == COMMIT
    assert metadata['digest'] == 'sha256:' + SHA256 and not metadata['expired']
    archive = Path(os.environ['RUNNER_TEMP']) / f'original-sprint-run{number}.zip'
    with opener.open(request(f'/actions/artifacts/{ARTIFACT}/zip'), timeout=120) as response, archive.open('wb') as output:
        shutil.copyfileobj(response, output)
    with archive.open('rb') as stream: actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    assert actual == SHA256
    out = Path(f'recovered-sprint-run{number}'); out.mkdir(exist_ok=True)
    selected = []
    with zipfile.ZipFile(archive) as source:
        assert source.testzip() is None
        for info in source.infolist():
            name = PurePosixPath(info.filename)
            assert not name.is_absolute() and '..' not in name.parts
            if info.is_dir() or any(p.endswith('.xcresult') for p in name.parts): continue
            if not (info.filename.startswith('Visual/') or name.suffix.lower() in {'.log', '.json', '.txt', '.tsv'}): continue
            target = out / name; target.parent.mkdir(parents=True, exist_ok=True)
            with source.open(info) as incoming, target.open('wb') as output: shutil.copyfileobj(incoming, output)
            with target.open('rb') as stream: sha = hashlib.file_digest(stream, 'sha256').hexdigest()
            selected.append({'path':str(name),'bytes':info.file_size,'sha256':sha})
    assert any(p['path'].endswith('xcode-sprint-focused-test.log') for p in selected)
    assert any(p['path'].endswith('manifest.json') for p in selected)
    (out/'RecoveryProvenance.json').write_text(json.dumps({'originalArtifact':metadata,'originalSHA256':actual,
        'originalZIPCRC':'PASS','operation':'Exact original exported visual evidence and logs, not a rerun; original raw xcresults remain in the original artifact.',
        'selectedFiles':selected},indent=2)+'\n')
    print('Verified immutable original artifact and recovered',len(selected),'unchanged exports;',sum(p['bytes'] for p in selected),'bytes.')

if __name__ == '__main__': main()
