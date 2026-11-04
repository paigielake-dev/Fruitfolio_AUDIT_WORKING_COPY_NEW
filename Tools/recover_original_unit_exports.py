#!/usr/bin/env python3
"""Select unchanged original unit logs/JSON from >512MiB immutable artifacts.
No tests are rerun, relabeled or deleted. Auth headers never follow redirects.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import urllib.request
import zipfile
from recover_run93_accessibility_exports import NoCredentialRedirect, request, REPO

ORIGINALS = {
    97: dict(run=41429324602, artifact=13137216630, sha='efbc2924fc96769caf01d6be57bedc1224a3715baf8920e3a576e392c9206bf5', commit='7ca11f1db89dbae985bc807626c5e17597bdba1e'),
    98: dict(run=41431534863, artifact=13138445667, sha='ed9fe304b3065c2cee4898605c4d83fbab654c43480febc863739a4b37a3d1bb', commit='31ec66554ec40ce056328f6b04cdc492a9e05c86')
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run_number', type=int, choices=sorted(ORIGINALS))
    number = parser.parse_args().run_number; original = ORIGINALS[number]
    assert os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('GITHUB_REPOSITORY') == REPO
    out = Path(f'recovered-unit-run{number}')
    if Path(f'Delivery/RecoveredUnitRun{number}.json').exists():
        print('Original unit recovery provenance already retained; do not reinterpret its historical results.'); return
    opener = urllib.request.build_opener(NoCredentialRedirect())
    with opener.open(request('/actions/artifacts/' + str(original['artifact'])), timeout=30) as response:
        metadata = json.load(response)
    assert metadata['id'] == original['artifact'] and metadata['name'] == 'Fruitfolio_Unit_Build_Evidence'
    assert metadata['workflow_run']['id'] == original['run'] and metadata['workflow_run']['head_sha'] == original['commit']
    assert metadata['digest'] == 'sha256:' + original['sha'] and not metadata['expired']
    archive = Path(os.environ['RUNNER_TEMP']) / f'original-unit-run{number}.zip'
    with opener.open(request('/actions/artifacts/' + str(original['artifact']) + '/zip'), timeout=120) as response, archive.open('wb') as destination:
        shutil.copyfileobj(response, destination)
    with archive.open('rb') as stream: actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    assert actual == original['sha']
    files = []
    with zipfile.ZipFile(archive) as source:
        assert source.testzip() is None
        for info in source.infolist():
            name = info.filename
            selected = name in ['xcode-unit-test.log', 'xcode-build.log'] or name.startswith('UnitAttachments/') and name.endswith(('.json', '.txt'))
            if not selected or info.is_dir(): continue
            assert '..' not in PurePosixPath(name).parts and not PurePosixPath(name).is_absolute()
            destination = out / name; destination.parent.mkdir(parents=True, exist_ok=True)
            with source.open(info) as original_file, destination.open('wb') as output:
                shutil.copyfileobj(original_file, output)
            with destination.open('rb') as stream: sha = hashlib.file_digest(stream, 'sha256').hexdigest()
            files.append(dict(path=name, bytes=info.file_size, sha256=sha))
    assert any(item['path'] == 'xcode-unit-test.log' for item in files)
    assert any(item['path'] == 'UnitAttachments/manifest.json' for item in files)
    (out/'RecoveryProvenance.json').write_text(json.dumps(dict(originalArtifact=metadata, verifiedOriginalSHA256=actual,
        originalZIPCRC='PASS', operation='Unchanged original log/JSON/text selection, not a test rerun or outcome modification; original archive retains all binary attachments.', selectedFiles=files), indent=2)+'\n')
    print('Verified immutable original archive and selected', len(files), 'original evidence files.')

if __name__ == '__main__': main()
