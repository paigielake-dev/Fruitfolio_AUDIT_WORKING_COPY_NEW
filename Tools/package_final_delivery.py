#!/usr/bin/env python3
"""Verify and package the real project. Never label unfinished work FINAL_COMPLETE."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKIP_PARTS = {'.git', '__pycache__', '.ciDerivedData', 'DerivedData', '.build-apple-runtime', 'target', 'VerificationDownloads', '.venv', 'node_modules', '.build'}
MODEL_HASHES = {'FruitfolioAI.gguf': '74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db',
                'Models/MADLAD/model-q4k.gguf': 'ea6e5531a3e95213c7f0635988d119e078a655c09306e47851e15d4c0c3f9c37'}
REQUIRED = ['Fruitfolio.xcodeproj/project.pbxproj', 'Fruitfolio.xcodeproj/xcshareddata/xcschemes/Fruitfolio.xcscheme',
            'Fruitfolio/FruitfolioResearchPackage.json', 'Fruitfolio/Localizable.xcstrings',
            'Delivery/ImplementationTracker478.json', 'Delivery/LatestAppleTestResults.json',
            'Fruitfolio_Verification_Evidence/requirement-to-evidence-index.csv',
            'Vendor/llama.xcframework/Info.plist', 'Vendor/FruitfolioMADLAD.xcframework/Info.plist',
            'Models/MADLAD/config.json', 'Models/MADLAD/tokenizer.json', 'Models/MADLAD/tokenizer_config.json',
            'Models/MADLAD/generation_config.json', 'Models/MADLAD/added_tokens.json',
            'Models/MADLAD/special_tokens_map.json', 'Models/MADLAD/spiece.model', *MODEL_HASHES]


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def included(path):
    rel = path.relative_to(ROOT)
    if any(part in SKIP_PARTS or part.endswith('.xcresult') for part in rel.parts): return False
    if rel.as_posix() == 'Delivery/CONTINUATION_ARCHIVE_FILES.json': return False
    if rel.parts.count('AppleRuns') > 1: return False  # duplicate embedded historical artifact trees
    if path.name == '.DS_Store' or path.suffix == '.pyc': return False
    if re.search(r'(?:\.before_|\.backup|_before_|_backup_|\.bak$|\.orig$)', path.name, re.I): return False
    if re.match(r'^\..*\.(?:gguf|pdf|mp4|png|wav|mp3|docx|zip)\.[A-Za-z0-9]{4,}(?:\..*)?$', path.name): return False
    return path.is_file()


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
    for name in ['llama', 'FruitfolioMADLAD']:
        folder = ROOT / 'Vendor' / (name + '.xcframework')
        info = plistlib.loads((folder / 'Info.plist').read_bytes())
        variants = set()
        for library in info['AvailableLibraries']:
            if 'arm64' not in library['SupportedArchitectures']: continue
            variants.add(library.get('SupportedPlatformVariant', 'device'))
            if not (folder / library['LibraryIdentifier'] / library['LibraryPath']).exists():
                raise RuntimeError('Missing actual runtime library: ' + name)
        if not {'device', 'simulator'} <= variants: raise RuntimeError('Missing ARM64 runtime slice: ' + name)
    for catalog in (ROOT / 'Fruitfolio/Assets.xcassets').rglob('Contents.json'):
        data = json.loads(catalog.read_text())
        for group in ['images', 'data', 'sounds']:
            for entry in data.get(group, []):
                filename = entry.get('filename')
                if filename and not (catalog.parent / filename).is_file():
                    raise RuntimeError('Missing catalog resource: ' + str(catalog.parent / filename))
    intelligence = (ROOT / 'Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift').read_text()
    start = intelligence.index('nonisolated enum FruitfolioGeneratedDraftValidator')
    end = intelligence.index('// MARK: - Research intelligence engine', start)
    if hashlib.sha256(intelligence[start:end].encode()).hexdigest() != '18354af8a8f3349a21648a77778702d59a9c42539d77c64d5577afc355182b60':
        raise RuntimeError('Strict grounding validator differs from authoritative 6ed804a baseline')
    tracker = json.loads((ROOT / 'Delivery/ImplementationTracker478.json').read_text())
    items = tracker['requirements']
    if len(items) != 478 or len({x['requirementID'] for x in items}) != 478: raise RuntimeError('Tracker must retain all 478 unique original requirements')
    for item in items:
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
    if args.verify_only:
        print(json.dumps({'inputIntegrity': 'PASS', 'releaseAcceptance': 'NOT CLAIMED', 'files': len(files), 'tracker': tracker['summary']}, indent=2)); return
    out = args.output_directory.resolve(); out.mkdir(parents=True, exist_ok=True)
    name = 'Fruitfolio_Prompt_1B_FINAL_COMPLETE.zip' if args.kind == 'final' else 'Fruitfolio_Prompt_1B_SNAPSHOT_' + args.source_commit[:12] + '.zip'
    archive = out / name
    if archive.exists(): raise FileExistsError('Refusing to overwrite an existing archive: ' + str(archive))
    manifest = {'sourceCommit': args.source_commit, 'deliveryStatus': 'FINAL COMPLETE' if args.kind == 'final' else 'INCOMPLETE INTERNAL SNAPSHOT — NOT FINAL ACCEPTANCE', 'files': []}
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
                if hashlib.file_digest(stream, 'sha256').hexdigest() != item['sha256']: raise RuntimeError('Changed or damaged file: ' + item['path'])
        # Read the actual extracted project/scheme bytes through ZIP decoding.
        if b'PBXProject' not in z.read(REQUIRED[0]) or b'<Scheme' not in z.read(REQUIRED[1]): raise RuntimeError('Project or shared scheme was not preserved')
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
             'bytes': archive.stat().st_size, 'sha256': digest(archive), 'files': len(files)+1, 'parts': parts}
    reconstructed = hashlib.sha256()
    for item in parts:
        with (out / item['name']).open('rb') as source:
            while chunk := source.read(8 * 1024 * 1024): reconstructed.update(chunk)
    if reconstructed.hexdigest() != index['sha256']: raise RuntimeError('Ordered parts do not reconstruct the exact archive')
    (out / (name + '.parts.json')).write_text(json.dumps(index, indent=2) + '\n')
    (out / (name + '.SHA256SUMS.txt')).write_text(''.join(p['sha256'] + '  ' + p['name'] + '\n' for p in parts) + index['sha256'] + '  ' + name + '\n')
    (out / (name + '.RECONSTRUCTION.txt')).write_text('Concatenate .part01, .part02, ... in numeric order to ' + name + '. Verify every part and full-archive SHA256 against the adjacent parts.json/SHA256SUMS files before extraction. These are binary split parts of one ZIP, not independent ZIP archives. Extract UTF-8 filenames intact, then open Fruitfolio.xcodeproj on an Apple Silicon Mac.\nStatus: ' + manifest['deliveryStatus'] + '\n')
    print(json.dumps(index, indent=2), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-commit', required=True)
    parser.add_argument('--kind', choices=['snapshot', 'final'], default='snapshot')
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--output-directory', type=Path, default=ROOT.parent / 'deliverables')
    parser.add_argument('--part-size-mib', type=int, default=400)
    options = parser.parse_args()
    if not re.fullmatch('[a-f0-9]{40}', options.source_commit) or not 1 <= options.part_size_mib <= 400:
        parser.error('A real 40-character source commit and 1–400 MiB part size are required')
    package(options)
