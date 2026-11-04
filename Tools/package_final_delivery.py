#!/usr/bin/env python3
"""Verify and package the real project. Never label unfinished work FINAL_COMPLETE."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import re
import tempfile
import unicodedata
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKIP_PARTS = {'.git', '__pycache__', '.ciDerivedData', 'DerivedData', '.build-apple-runtime', 'target', 'VerificationDownloads', '.venv', 'node_modules', '.build'}
MODEL_HASHES = {'FruitfolioAI.gguf': '74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db',
                'Models/MADLAD/model-q4k.gguf': 'ea6e5531a3e95213c7f0635988d119e078a655c09306e47851e15d4c0c3f9c37'}
REQUIRED = ['Specification/Fruitfolio_Prompt_1B_COMPLETE_ALL_CORRECTIONS_2026-10-16.doc',
            'Specification/Fruitfolio_Prompt_1B_Change_Breakdown_478.md',
            'Specification/Prompt1B_Extracted_Text.txt', 'Delivery/FOUNDER_MAC_VERIFICATION.md',
            'Fruitfolio.xcodeproj/project.pbxproj', 'Fruitfolio.xcodeproj/xcshareddata/xcschemes/Fruitfolio.xcscheme',
            'Fruitfolio/FruitfolioResearchPackage.json', 'Fruitfolio/Localizable.xcstrings',
            'Delivery/ImplementationTracker478.json', 'Delivery/LatestAppleTestResults.json',
            'Fruitfolio_Verification_Evidence/requirement-to-evidence-index.csv',
            'Vendor/llama.xcframework/Info.plist', 'Vendor/FruitfolioMADLAD.xcframework/Info.plist',
            'Models/MADLAD/config.json', 'Models/MADLAD/tokenizer.json', 'Models/MADLAD/tokenizer_config.json',
            'Models/MADLAD/generation_config.json', 'Models/MADLAD/added_tokens.json',
            'Models/MADLAD/special_tokens_map.json', 'Models/MADLAD/spiece.model', *MODEL_HASHES]


def stream_digest(stream):
    result = hashlib.sha256()
    while block := stream.read(8 * 1024 * 1024): result.update(block)
    return result.hexdigest()


def digest(path):
    with path.open('rb') as stream:
        return stream_digest(stream)


def included(path):
    rel = path.relative_to(ROOT)
    if any(part in SKIP_PARTS or part.endswith('.xcresult') for part in rel.parts): return False
    if rel.parts[0] in {'Leaderboard_Preparation_Backup', 'FruitBasket_Leaderboard_Backup_20261012_061959'}: return False  # inactive historical copies, absent from project roots/references
    if rel.parts[:2] in [('Vendor', 'ios-arm64'), ('Vendor', 'ios-arm64-simulator'), ('Vendor', 'LegacyMacOS')]: return False  # inactive/identical duplicate distributions; actual XCFrameworks remain required
    if rel.as_posix() == 'Vendor/Info.plist': return False  # duplicate MADLAD XCFramework manifest, not a project dependency
    if rel.as_posix() == 'Delivery/CONTINUATION_ARCHIVE_FILES.json': return False
    if rel.parts.count('AppleRuns') > 1: return False  # duplicate embedded historical artifact trees
    if path.name == '.DS_Store' or path.suffix == '.pyc': return False
    if re.search(r'(?:\.before_|\.backup|_before_|_backup_|\.bak$|\.orig$)', path.name, re.I): return False
    if re.match(r'^\..*\.(?:gguf|pdf|mp4|png|wav|mp3|docx|zip)\.[A-Za-z0-9]{4,}(?:\..*)?$', path.name): return False
    return path.is_file()


def verify_strict_validator(intelligence):
    start = intelligence.index('nonisolated enum FruitfolioGeneratedDraftValidator')
    end = intelligence.index('// MARK: - Research intelligence engine', start)
    validator = intelligence[start:end]
    identity_guard = '        guard evidence.hasUnambiguousEvidenceIdentity else { return nil }\n'
    if validator.count(identity_guard) != 1 or validator.index(identity_guard) > validator.index('let noteByID = Dictionary('):
        raise RuntimeError('Strict grounding identity preflight is missing or moved after unsafe indexing')
    # The only authorized change to the original validator is this stricter
    # duplicate/blank-identity preflight. Removing exactly that added line must
    # reproduce the complete authoritative 6ed804a validator, byte for byte.
    original = validator.replace(identity_guard, '', 1)
    if hashlib.sha256(original.encode()).hexdigest() != '18354af8a8f3349a21648a77778702d59a9c42539d77c64d5577afc355182b60':
        raise RuntimeError('Strict grounding validation differs beyond the authorized identity preflight')
    return {'originalValidatorSHA256': hashlib.sha256(original.encode()).hexdigest(),
            'currentValidatorSHA256': hashlib.sha256(validator.encode()).hexdigest(),
            'authorizedAddition': 'duplicate/blank evidence identity preflight before Dictionary indexing'}


def verify_inputs():
    for rel in REQUIRED:
        if not (ROOT / rel).is_file(): raise RuntimeError('Missing required build/delivery resource: ' + rel)
    expected_resources = dict(MODEL_HASHES)
    runtime = (ROOT / 'Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift').read_text()
    configurations = re.findall(r'\("([^"/]+)", "([a-f0-9]{64})"\)', runtime)
    if len(configurations) != 8: raise RuntimeError('The exact official MADLAD resource integrity table is incomplete')
    for name, expected in configurations: expected_resources['Models/MADLAD/' + name] = expected
    for rel, expected in expected_resources.items():
        if digest(ROOT / rel) != expected: raise RuntimeError('Model/tokenizer/configuration integrity failure: ' + rel)
    runtime_provenance = {r['name']: r for r in json.loads((ROOT / 'Delivery/TESTED_LOCAL_RUNTIME_PROVENANCE.json').read_text())['runtimes']}
    for name in ['llama', 'FruitfolioMADLAD']:
        folder = ROOT / 'Vendor' / (name + '.xcframework')
        info = plistlib.loads((folder / 'Info.plist').read_bytes())
        variants = set()
        for library in info['AvailableLibraries']:
            if 'arm64' not in library['SupportedArchitectures']: continue
            variants.add(library.get('SupportedPlatformVariant', 'device'))
            payload = folder / library['LibraryIdentifier'] / library['LibraryPath']
            if payload.is_dir(): payload = payload / payload.stem
            if not payload.is_file(): raise RuntimeError('Missing actual runtime library: ' + name)
            expected = next((r for r in runtime_provenance[name]['libraries'] if r['slice'] == library['LibraryIdentifier']), None)
            if expected is None or payload.stat().st_size != expected['bytes'] or digest(payload) != expected['sha256']:
                raise RuntimeError('Runtime differs from preserved actually tested binary: ' + str(payload))
        if not {'device', 'simulator'} <= variants: raise RuntimeError('Missing ARM64 runtime slice: ' + name)
    for catalog in (ROOT / 'Fruitfolio/Assets.xcassets').rglob('Contents.json'):
        data = json.loads(catalog.read_text())
        for group in ['images', 'data', 'sounds']:
            for entry in data.get(group, []):
                filename = entry.get('filename')
                if filename and not (catalog.parent / filename).is_file():
                    raise RuntimeError('Missing catalog resource: ' + str(catalog.parent / filename))
    source_inventory = json.loads((ROOT / 'Fruitfolio_Verification_Evidence/FiveHourSprint/Phase8Integration/IntegratedSourceByteVerification316.json').read_text())
    expected_source_paths = set()
    for record in source_inventory['rows']:
        path = ROOT / record['path']
        if not path.is_file(): raise RuntimeError('Verified active source disappeared: ' + record['path'])
        data = path.read_bytes()
        actual = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
        expected = record.get('remoteGitBlobSHA', record['sha'])
        if actual != expected: raise RuntimeError('Active source differs from verified GitHub bytes: ' + record['path'])
        expected_source_paths.add(record['path'])
    for folder in ['Fruitfolio', 'FruitfolioTests', 'FruitfolioUITests']:
        for path in (ROOT / folder).rglob('*.swift'):
            if path.relative_to(ROOT).as_posix() not in expected_source_paths:
                raise RuntimeError('Active Swift source is absent from verified Git inventory: ' + str(path))
    for source_root in ['Fruitfolio', 'FruitfolioTests', 'FruitfolioUITests']:
        for path in (ROOT / source_root).rglob('*.swift'):
            text = path.read_bytes().decode('utf-8', errors='strict')
            if re.search(r'(?:[0-9]+ tokens truncated|Warning: truncated output|original token count:)', text):
                raise RuntimeError('Truncated tool output contaminated active Swift source: ' + str(path))
    project = (ROOT / 'Fruitfolio.xcodeproj/project.pbxproj').read_text()
    if 'llama.swiftui.xcodeproj' in project:
        raise RuntimeError('Obsolete missing example subproject reference remains in the delivery project')
    for record in re.findall(r'isa = PBXFileReference;([^}]+)', project):
        if not re.search(r'sourceTree\s*=\s*SOURCE_ROOT\s*;', record): continue
        match = re.search(r'path\s*=\s*(?:"([^"]+)"|([^;]+));', record)
        if match:
            rel = (match.group(1) or match.group(2)).strip()
            if not (ROOT / rel).exists(): raise RuntimeError('Missing SOURCE_ROOT project reference: ' + rel)
    for record in re.findall(r'isa = PBXFileSystemSynchronizedRootGroup;([^}]+)', project):
        match = re.search(r'path\s*=\s*(?:"([^"]+)"|([^;]+));', record)
        if match:
            rel = (match.group(1) or match.group(2)).strip()
            if not (ROOT / rel).is_dir(): raise RuntimeError('Missing synchronized source root: ' + rel)
    verify_strict_validator((ROOT / 'Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift').read_text())
    tracker = json.loads((ROOT / 'Delivery/ImplementationTracker478.json').read_text())
    items = tracker['requirements']
    if len(items) != 478 or len({x['requirementID'] for x in items}) != 478: raise RuntimeError('Tracker must retain all 478 unique original requirements')
    actual_counts = dict(Counter(item['implementationStatus'] for item in items))
    if tracker.get('summary') != actual_counts:
        raise RuntimeError('Tracker summary is stale; reconcile it against all 478 individual statuses')
    for item in items:
        if item.get('finalDisposition', item['implementationStatus']) != item['implementationStatus']:
            raise RuntimeError('Conflicting item disposition: ' + item['requirementID'])
        for ref in set(item.get('supportingEvidence', []) + item.get('evidenceReferences', [])):
            p = ROOT / ref.split('#')[0]
            if not p.exists() or not included(p): raise RuntimeError('Missing or excluded required evidence: ' + ref)
    return tracker


def final_gate(tracker, commit):
    if any(x['implementationStatus'] != 'PASS' for x in tracker['requirements']):
        raise RuntimeError('FINAL_COMPLETE refused: not every required item has actual PASS acceptance. Use an explicitly named internal snapshot to preserve unfinished work.')
    report = json.loads((ROOT / 'Delivery/ReleaseAcceptance.json').read_text())
    checks = ['actualBuild', 'unitTests', 'uiTests', 'accessibility', 'offlineAsk', 'offlineMADLAD', 'localization', 'deviceCompatibility']
    if report.get('sourceCommit') != commit or any(report.get(key) != 'PASS' for key in checks) or report.get('unresolvedRequiredItems') != []:
        raise RuntimeError('FINAL_COMPLETE refused: exact final-source acceptance is missing or incomplete')


def package(args):
    tracker = verify_inputs()
    if args.kind == 'final': final_gate(tracker, args.source_commit)
    files = [(p, p.relative_to(ROOT).as_posix()) for p in sorted(ROOT.rglob('*')) if included(p)]
    canonical_names = {}
    for _, rel in files:
        canonical = unicodedata.normalize('NFC', rel).casefold()
        if canonical in canonical_names and canonical_names[canonical] != rel:
            raise RuntimeError('Case/Unicode filename collision on common Mac filesystems: ' + canonical_names[canonical] + ' / ' + rel)
        canonical_names[canonical] = rel

    if args.verify_only:
        print(json.dumps({'inputIntegrity': 'PASS', 'releaseAcceptance': 'NOT CLAIMED', 'files': len(files), 'tracker': tracker['summary']}, indent=2)); return
    out = args.output_directory.resolve()
    if out == ROOT or ROOT in out.parents:
        raise RuntimeError('Delivery output must be outside the project root to avoid packaging prior archives or extraction caches')
    out.mkdir(parents=True, exist_ok=True)
    name = ('Fruitfolio_Prompt_1B_FINAL_COMPLETE.zip' if args.kind == 'final' else
            'Fruitfolio_Prompt_1B_INTEGRATED_SOURCE.zip' if args.kind == 'integrated' else
            'Fruitfolio_Prompt_1B_SNAPSHOT_' + args.source_commit[:12] + '.zip')
    archive = out / name
    if archive.exists(): raise FileExistsError('Refusing to overwrite an existing archive: ' + str(archive))
    status = ('FINAL COMPLETE' if args.kind == 'final' else
              'INTEGRATED SOURCE HANDOFF — INCOMPLETE RELEASE ACCEPTANCE' if args.kind == 'integrated' else
              'INCOMPLETE INTERNAL SNAPSHOT — NOT FINAL ACCEPTANCE')
    manifest = {'sourceCommit': args.source_commit, 'sourceTree': args.source_tree,
                'developmentBranch': args.branch, 'deliveryStatus': status, 'files': []}
    for path, rel in files:
        manifest['files'].append({'path': rel, 'bytes': path.stat().st_size, 'sha256': digest(path)})
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as z:
        for path, rel in files: z.write(path, rel)
        z.writestr('Delivery/PackagedFileIntegrity.json', json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None: raise RuntimeError('Archive CRC failure')
        names = z.namelist()
        if len(names) != len(set(names)): raise RuntimeError('Duplicate archive paths')
        for rel in names:
            p = PurePosixPath(rel)
            if p.is_absolute() or '..' in p.parts or '\x00' in rel: raise RuntimeError('Unsafe archive path')
            rel.encode('utf-8', errors='strict')
        for item in manifest['files']:
            with z.open(item['path']) as stream:
                if stream_digest(stream) != item['sha256']: raise RuntimeError('Changed or damaged file: ' + item['path'])
        # Read the actual extracted project/scheme bytes through ZIP decoding.
        if b'PBXProject' not in z.read('Fruitfolio.xcodeproj/project.pbxproj') or b'<Scheme' not in z.read('Fruitfolio.xcodeproj/xcshareddata/xcschemes/Fruitfolio.xcscheme'): raise RuntimeError('Project or shared scheme was not preserved')
    extraction_verified = False
    if args.kind in {'integrated', 'final'}:
        with tempfile.TemporaryDirectory(prefix='Fruitfolio-Extraction-Check-', dir=out) as temporary:
            extracted = Path(temporary)
            with zipfile.ZipFile(archive) as z: z.extractall(extracted)
            for item in manifest['files']:
                actual = extracted / item['path']
                if not actual.is_file() or digest(actual) != item['sha256']:
                    raise RuntimeError('Physical extraction changed a file or filename: ' + item['path'])
            if b'PBXProject' not in (extracted / 'Fruitfolio.xcodeproj/project.pbxproj').read_bytes():
                raise RuntimeError('Extracted Xcode project is unreadable')
            extraction_verified = True
    parts = []; part_size = args.part_size_mib * 1024 * 1024
    with archive.open('rb') as source:
        while True:
            first = source.read(min(8 * 1024 * 1024, part_size))
            if not first: break
            path = out / (name + '.part' + f'{len(parts)+1:02d}')
            size = 0
            with path.open('xb') as dest:
                dest.write(first); size += len(first)
                while size < part_size:
                    chunk = source.read(min(8 * 1024 * 1024, part_size - size))
                    if not chunk: break
                    dest.write(chunk); size += len(chunk)
            parts.append({'name': path.name, 'bytes': size, 'sha256': digest(path)})
    index = {'archive': name, 'status': manifest['deliveryStatus'], 'sourceCommit': args.source_commit,
             'sourceTree': args.source_tree, 'developmentBranch': args.branch,
             'bytes': archive.stat().st_size, 'sha256': digest(archive), 'files': len(files)+1, 'parts': parts,
             'verification': {'zipCRC': 'PASS', 'everyManifestFileSHA256': 'PASS', 'safeUTF8Paths': 'PASS',
                              'physicalExtractionAndFileReadback': 'PASS' if extraction_verified else 'NOT EXECUTED',
                              'requiredResourceInclusion': 'PASS', 'releaseAcceptance': 'NOT CLAIMED'}}
    reconstructed = hashlib.sha256()
    for item in parts:
        with (out / item['name']).open('rb') as source:
            while chunk := source.read(8 * 1024 * 1024): reconstructed.update(chunk)
    if reconstructed.hexdigest() != index['sha256']: raise RuntimeError('Ordered parts do not reconstruct the exact archive')
    (out / (name + '.parts.json')).write_text(json.dumps(index, indent=2) + '\n')
    (out / (name + '.SHA256SUMS.txt')).write_text(''.join(p['sha256'] + '  ' + p['name'] + '\n' for p in parts) + index['sha256'] + '  ' + name + '\n')
    (out / 'RECONSTRUCT_FRUITFOLIO.py').write_bytes((ROOT / 'Tools/reconstruct_delivery.py').read_bytes())
    (out / (name + '.RECONSTRUCTION.txt')).write_text(
        'Download every .part01, .part02, ... file and the matching .parts.json into one folder. '
        'These are binary pieces of one ZIP, not separate ZIP archives. Download RECONSTRUCT_FRUITFOLIO.py too.\n'
        'From that folder run: python3 RECONSTRUCT_FRUITFOLIO.py ' + name + '.parts.json\n'
        'The script verifies each exact part size/SHA256, numeric sequence and whole-archive SHA256 before publishing the ZIP. '
        'It never overwrites a different existing ZIP. No network access or model execution occurs.\n'
        'Alternatively concatenate all .partNN files in numeric order to ' + name + ' and verify SHA256SUMS.\n'
        'Extract UTF-8 filenames intact, then open Fruitfolio.xcodeproj on an Apple Silicon Mac; see Delivery/FOUNDER_MAC_VERIFICATION.md.\n'
        'Status: ' + manifest['deliveryStatus'] + '\n')
    print(json.dumps(index, indent=2), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-commit', required=True)
    parser.add_argument('--kind', choices=['snapshot', 'integrated', 'final'], default='snapshot')
    parser.add_argument('--source-tree', help='Verified GitHub tree SHA; required for integrated/final delivery')
    parser.add_argument('--branch', default='fruitfolio/prompt-1b-alignment')
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--output-directory', type=Path, default=ROOT.parent / 'deliverables')
    parser.add_argument('--part-size-mib', type=int, default=400)
    options = parser.parse_args()
    if not re.fullmatch('[a-f0-9]{40}', options.source_commit) or not 1 <= options.part_size_mib <= 400:
        parser.error('A real 40-character source commit and 1–400 MiB part size are required')
    if options.kind in {'integrated', 'final'} and not re.fullmatch('[a-f0-9]{40}', options.source_tree or ''):
        parser.error('Integrated/final delivery requires the actual verified remote source tree SHA')
    package(options)
