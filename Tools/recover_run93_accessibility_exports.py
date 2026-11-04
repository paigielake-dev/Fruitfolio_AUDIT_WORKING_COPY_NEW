#!/usr/bin/env python3
"""Recover exported evidence from the immutable original artifact, not test results.

The connector cannot transfer its >512MiB ZIP. This read-only CI recovery checks
its digest/CRC, selects existing exported attachments and retains provenance.
It never reruns/relabels the tests or edits/deletes the original artifact.
"""
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import urllib.request
import zipfile

REPO = 'paigielake-dev/Fruitfolio_AUDIT_WORKING_COPY_NEW'
ARTIFACT = 13131624869
RUN = 41424238318
COMMIT = '309a3a7dfa797209ee1ce3c71f70861a3e1276d1'
SHA = '89a2e9ba17a92600886cfdedc3226bbf63dd1e4875a9aa2b6236fd7de2713c8e'
OUT = Path('recovered-run93-accessibility')


class NoCredentialRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        redirected = super().redirect_request(request, fp, code, msg, headers, newurl)
        if redirected is not None:
            redirected.remove_header('Authorization')
        return redirected


def request(path):
    return urllib.request.Request('https://api.github.com/repos/' + REPO + path,
        headers={'Authorization': 'Bearer ' + os.environ['GH_TOKEN'],
                 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'})


def main():
    assert os.environ.get('GITHUB_ACTIONS') == 'true'
    assert os.environ.get('GITHUB_REPOSITORY') == REPO
    if Path('Fruitfolio_Verification_Evidence/AppleRuns/Run93/AccessibilityAudit/RecoveryProvenance.json').exists():
        print('Original log/provenance are tracked; full immutable exports remain in Run96 recovery artifact13133835033. No duplicate transfer or new test acceptance.')
        return
    opener = urllib.request.build_opener(NoCredentialRedirect())
    with opener.open(request('/actions/artifacts/' + str(ARTIFACT)), timeout=30) as response:
        metadata = json.load(response)
    assert metadata['id'] == ARTIFACT and metadata['name'] == 'Fruitfolio_Accessibility_Audit_Evidence'
    assert metadata['workflow_run']['id'] == RUN and metadata['workflow_run']['head_sha'] == COMMIT
    assert metadata['digest'] == 'sha256:' + SHA and not metadata['expired']
    archive = Path(os.environ['RUNNER_TEMP']) / 'fruitfolio-run93-original-a11y.zip'
    with opener.open(request('/actions/artifacts/' + str(ARTIFACT) + '/zip'), timeout=120) as response, archive.open('wb') as output:
        shutil.copyfileobj(response, output)
    digest = hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest()
    assert digest == SHA
    selected = []
    with zipfile.ZipFile(archive) as source:
        assert source.testzip() is None
        for info in source.infolist():
            name = info.filename
            if not (name == 'Build/xcode-accessibility-audit-ui-test.log' or name.startswith('Visual/AccessibilityAudit/')):
                continue
            assert '..' not in PurePosixPath(name).parts and not PurePosixPath(name).is_absolute()
            if info.is_dir():
                continue
            destination = OUT / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            with source.open(info) as original, destination.open('wb') as output:
                shutil.copyfileobj(original, output)
            selected.append({'path': name, 'bytes': info.file_size,
                             'sha256': hashlib.file_digest(destination.open('rb'), 'sha256').hexdigest()})
    assert any(item['path'].endswith('.log') for item in selected)
    assert any(item['path'].endswith('manifest.json') for item in selected)
    OUT.mkdir(exist_ok=True)
    (OUT / 'RecoveryProvenance.json').write_text(json.dumps({'originalArtifact': metadata,
        'verifiedOriginalSHA256': digest, 'originalZIPCRC': 'PASS',
        'operation': 'Byte-for-byte selection of original exported attachments and log; no test outcome modification',
        'selectedFiles': selected}, indent=2) + '\n')
    print('Verified original archive SHA/CRC and recovered', len(selected), 'unchanged exported evidence files.')


if __name__ == '__main__':
    main()
