#!/usr/bin/env python3
"""Local founder research validation, preview, atomic publication and rollback.

This is an offline, build-time tool. Structural validation does not establish
scientific truth. Publication requires a separate, hash-bound human review record.
No downloads, automatic medical approval, gameplay modifications or data migrations.
"""
import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import tempfile


class Rejected(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise Rejected(message)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def decode(raw):
    def unique_pairs(pairs):
        value = {}
        for key, item in pairs:
            require(key not in value, f'duplicate JSON key: {key}')
            value[key] = item
        return value
    return json.loads(raw.decode("utf-8") if isinstance(raw, bytes) else raw, object_pairs_hook=unique_pairs,
                      parse_constant=lambda value: (_ for _ in ()).throw(Rejected(f"Non-JSON constant: {value}")))


def records(package, key, identifier):
    rows = package.get(key)
    require(isinstance(rows, list), f'{key}: expected array')
    result = {}
    for row in rows:
        require(isinstance(row, dict), f'{key}: expected object')
        ident = row.get(identifier)
        require(isinstance(ident, str) and ident.strip(), f'{key}: missing stable identifier')
        require(ident not in result, f'{key}: duplicate identifier {ident}')
        result[ident] = row
    return result


def validate(raw, manifest, baseline=None):
    package = decode(raw)
    require(type(package.get('schemaVersion')) is int and package['schemaVersion'] == 1, 'Unsupported application research schema; explicit migration required')
    version = package.get('contentVersion', '')
    require(isinstance(version, str) and re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]{0,199}', version), 'Invalid contentVersion')
    for field in ['generatedFrom', 'generationNote']:
        require(isinstance(package.get(field), str) and package[field].strip(), f'Missing provenance field: {field}')
    sources = records(package, 'sources', 'sourceID')
    notes = records(package, 'researchNoteChunks', 'chunkID')
    chunks = records(package, 'sourceChunks', 'sourceChunkID')
    require(sources and (notes or chunks), 'Empty/incomplete research package')
    require(manifest.get('schemaVersion') == 1 and manifest.get('packageSHA256') == digest(raw), 'Manifest must bind the exact proposed bytes')
    topics = manifest.get('supportedTopicIDs')
    require(isinstance(topics, list) and len(set(topics)) == len(topics) and all(isinstance(t, str) and t.strip() for t in topics), 'Explicit unique supportedTopicIDs required')
    for ident, source in sources.items():
        for field in ['title', 'sourceVersion', 'contentVersion', 'verificationStatus']:
            require(isinstance(source.get(field), str) and source[field].strip(), f'{ident}: missing {field}')
        require(isinstance(source.get('retrievalEligibility'), bool), f'{ident}: explicit retrievalEligibility required')
        if source['retrievalEligibility']:
            require(source['verificationStatus'] in ['verified', 'founderCorpusAPA7'], f'{ident}: unresolved/conflicted source cannot be eligible')
            require(isinstance(source.get('apa7Reference'), str) and source['apa7Reference'].strip(), f'{ident}: missing citation')
            require('publicationDate' in source and 'publicationType' in source, f'{ident}: publication details required; unknown date must be explicit null')
    for ident, source in sources.items():
        for field in ['authors', 'organization', 'publicationDate', 'publicationType', 'canonicalURL', 'doi', 'apa7Reference', 'verifiedAt']:
            require(source.get(field) is None or isinstance(source[field], str), f'{ident}: invalid {field}')
    for ident, note in notes.items():
        require(isinstance(note.get('heading'), str) and note['heading'].strip(), f'{ident}: missing heading')
        require(note.get('subheading') is None or isinstance(note['subheading'], str), f'{ident}: invalid subheading')
        for field in ['semanticTags', 'domainTags']:
            require(isinstance(note.get(field), list) and all(isinstance(t, str) for t in note[field]), f'{ident}: invalid {field}')
        require(note.get('researchTopicID') in topics, f'{ident}: unsupported topic')
        require(isinstance(note.get('text'), str) and note['text'].strip(), f'{ident}: missing approved explanation/passage')
        links = note.get('sourceIDs')
        require(isinstance(links, list) and links and len(set(links)) == len(links), f'{ident}: missing/duplicate source references')
        require(all(link in sources and sources[link]['retrievalEligibility'] for link in links), f'{ident}: broken or ineligible supporting source')
    for ident, chunk in chunks.items():
        require(isinstance(chunk.get('claimCategories'), list) and all(isinstance(t, str) for t in chunk['claimCategories']), f'{ident}: invalid claimCategories')
        for field in ['section', 'locationMetadata']:
            require(chunk.get(field) is None or isinstance(chunk[field], str), f'{ident}: invalid {field}')
        require(chunk.get('sourceID') in sources, f'{ident}: broken source reference')
        require(isinstance(chunk.get('text'), str) and chunk['text'].strip(), f'{ident}: empty source passage')
    if baseline:
        require(package['contentVersion'] != baseline['contentVersion'], 'A revision needs a new contentVersion')
        for key, field in [('sources', 'sourceID'), ('researchNoteChunks', 'chunkID'), ('sourceChunks', 'sourceChunkID')]:
            old = records(baseline, key, field)
            new = records(package, key, field)
            retired = manifest.get('retiredIDs', {}).get(key, [])
            require(isinstance(retired, list) and len(set(retired)) == len(retired), f'{key}: invalid retiredIDs')
            require(set(retired) == set(old) - set(new), f'{key}: removal/retirement must be explicit and exact')
            if key == 'sources':
                for ident in set(old) & set(new):
                    if old[ident] != new[ident]:
                        require(old[ident]['sourceVersion'] != new[ident]['sourceVersion'], f'{ident}: changed source needs a new sourceVersion')
    return package


def require_review(raw, review):
    require(review.get('packageSHA256') == digest(raw), 'Review does not match the exact candidate bytes')
    require(review.get('founderApproved') is True and review.get('scientificReviewApproved') is True, 'Founder and qualified scientific review required; validation is not clinical approval')
    for field in ['reviewer', 'qualifications', 'reviewedAt', 'scope', 'evidenceAssessment', 'revisionReason']:
        require(isinstance(review.get(field), str) and review[field].strip(), f'Missing review field: {field}')


def atomic_write(path, raw):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.pending-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(raw); stream.flush(); os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()


def read_current(root):
    path = root / 'CURRENT.json'
    return decode(path.read_bytes()) if path.exists() else None


def snapshot(root, sha):
    require(isinstance(sha, str) and re.fullmatch(r'[0-9a-f]{64}', sha), 'Invalid snapshot digest')
    directory = root / 'snapshots' / sha
    raw = (directory / 'package.json').read_bytes()
    require(digest(raw) == sha, 'Archived snapshot integrity failed')
    manifest = decode((directory / 'manifest.json').read_bytes())
    review = decode((directory / 'review.json').read_bytes())
    validate(raw, manifest); require_review(raw, review)
    return raw


@contextmanager
def publication_lock(root):
    root.mkdir(parents=True, exist_ok=True)
    with (root / '.publication.lock').open('a+b') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def publish(root, raw, manifest, review):
    with publication_lock(root):
        return _publish(root, raw, manifest, review)


def _publish(root, raw, manifest, review):
    current = read_current(root)
    baseline = decode(snapshot(root, current['activeSHA256'])) if current else None
    package = validate(raw, manifest, baseline); require_review(raw, review)
    sha = digest(raw)
    # All historical snapshots remain immutable. Reusing a display version for
    # different bytes is rejected even after rolling back to another version.
    for old in (root / 'snapshots').glob('*/package.json'):
        require(decode(old.read_bytes())['contentVersion'] != package['contentVersion'] or digest(old.read_bytes()) == sha, 'contentVersion already names different historical bytes')
    directory = root / 'snapshots' / sha
    require(not directory.exists(), 'Snapshot already exists; use rollback instead of rewriting history')
    directory.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix='.staging-', dir=directory.parent))
    try:
        # Publish the complete immutable directory only after all writes finish.
        atomic_write(staging / 'package.json', raw)
        atomic_write(staging / 'manifest.json', json_bytes(manifest))
        atomic_write(staging / 'review.json', json_bytes(review))
        require((staging / 'package.json').read_bytes() == raw, 'Staged bytes differ')
        os.rename(staging, directory)
    finally:
        if staging.exists():
            shutil.rmtree(staging)
    snapshot(root, sha)
    state = dict(schemaVersion=1, activeSHA256=sha, previousSHA256=current['activeSHA256'] if current else None)
    atomic_write(root / 'CURRENT.json', json_bytes(state))
    return state


def rollback(root):
    with publication_lock(root):
        return _rollback(root)


def _rollback(root):
    current = read_current(root)
    require(current and current.get('previousSHA256'), 'No previous validated snapshot')
    snapshot(root, current['previousSHA256'])
    state = dict(schemaVersion=1, activeSHA256=current['previousSHA256'], previousSHA256=current['activeSHA256'])
    atomic_write(root / 'CURRENT.json', json_bytes(state))
    return state


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['validate', 'preview', 'publish', 'rollback', 'install'])
    parser.add_argument('--package', type=Path)
    parser.add_argument('--manifest', type=Path)
    parser.add_argument('--review', type=Path)
    parser.add_argument('--root', type=Path, default=Path('ResearchUpdates'))
    parser.add_argument('--destination', type=Path)
    args = parser.parse_args()
    if args.action == 'rollback':
        print(json.dumps(rollback(args.root))); return
    if args.action == 'install':
        require(args.destination is not None, '--destination is required')
        current = read_current(args.root)
        require(current is not None, 'No approved local snapshot')
        raw = snapshot(args.root, current['activeSHA256'])
        atomic_write(args.destination, raw)
        require(args.destination.read_bytes() == raw, 'Installed bytes differ')
        print('Installed exact approved bytes for the NEXT application build; active running sessions are unchanged.'); return
    require(args.package is not None and args.manifest is not None, '--package and --manifest are required')
    raw = args.package.read_bytes(); manifest = decode(args.manifest.read_bytes())
    current = read_current(args.root)
    baseline = decode(snapshot(args.root, current['activeSHA256'])) if current else None
    package = validate(raw, manifest, baseline)
    if args.action == 'publish':
        require(args.review is not None, '--review is required')
        print(json.dumps(publish(args.root, raw, manifest, decode(args.review.read_bytes()))))
    elif args.action == 'preview':
        print(json.dumps(dict(contentVersion=package['contentVersion'], researchNoteChunks=package['researchNoteChunks'], sources=package['sources'], structuralValidationOnly=True), ensure_ascii=False, indent=2))
    else:
        print('Structural validation passed; scientific and founder approval are NOT implied.')


if __name__ == '__main__':
    try:
        main()
    except (Rejected, OSError, ValueError, KeyError, TypeError) as error:
        raise SystemExit(f'REJECTED: {error}')
