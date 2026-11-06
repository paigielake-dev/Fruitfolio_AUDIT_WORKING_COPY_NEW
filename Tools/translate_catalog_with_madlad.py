#!/usr/bin/env python3
"""Generate review-only UI drafts with the app's actual offline MADLAD runtime.
Never edits the input catalog, marks strings translated, downloads weights, or
substitutes the Ask assistant model. Build the native runner with --build-only.
"""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCES = [
    'Core/AppArchitecture/FruitfolioLanguage.swift',
    'Core/Translation/FruitfolioMADLADModels.swift',
    'Core/Translation/FruitfolioMADLADRuntime.swift',
    'Core/Translation/FruitfolioLlamaBackend.swift',
    'Core/Translation/FruitfolioScientificQuantities.swift',
    'Core/Translation/FruitfolioScientificTranslation.swift',
]
FORMAT = re.compile(r'%%|%(?:\d+\$)?[-+#0 ]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|ll|[hlLzjt])?[@diuoxXfFeEgGaAcCsSp]')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')
    temporary.replace(path)


def build_runner(swift, native_build, output):
    """Compile exact production sources and real native archives, no stubs."""
    libraries = [native_build / 'src/libllama.a', native_build / 'ggml/src/libggml.a',
                 native_build / 'ggml/src/libggml-cpu.a', native_build / 'ggml/src/libggml-base.a']
    for library in libraries:
        if not library.is_file():
            raise ValueError(f'missing actual native archive: {library}')
    with tempfile.TemporaryDirectory(prefix='fruitfolio-madlad-runner-') as temporary:
        work = Path(temporary)
        include = work / 'llama/include'
        include.mkdir(parents=True)
        for directory in [ROOT / 'llama.cpp/include', ROOT / 'llama.cpp/ggml/include']:
            for header in directory.glob('*.h'):
                shutil.copyfile(header, include / header.name)
        (include.parent / 'module.modulemap').write_text('module llama [system] { header "include/llama.h" export * }\n')
        output.parent.mkdir(parents=True, exist_ok=True)
        command = [swift, '-swift-version', '5', '-parse-as-library', '-I', str(include.parent),
                   '-module-cache-path', str(work / 'module-cache')]
        command += [str(ROOT / 'Fruitfolio' / source) for source in SOURCES]
        command += [str(ROOT / 'Tools/MADLADCatalogRunner.swift')]
        command += [str(library) for library in libraries]
        command += ['-lc++' if platform.system() == 'Darwin' else '-lstdc++', '-lm', '-lpthread']
        if platform.system() == 'Linux':
            command += ['-ldl']
        command += ['-o', str(output)]
        subprocess.run(command, check=True)


def translate_catalog(catalog, resource_directory, runner, output, locales, limit=None):
    if output.resolve() == catalog.resolve():
        raise ValueError('draft output must be separate from the source catalog')
    original = catalog.read_bytes()
    data = json.loads(original)
    manifest = resource_directory / 'MADLAD400.manifest.json'
    report = {'schemaVersion': 1, 'engine': 'application-offline-MADLAD',
              'reviewStatus': 'unreviewed-machine-draft', 'catalogSHA256': digest(original),
              'manifestSHA256': digest(manifest.read_bytes()) if manifest.is_file() else None,
              'runnerSHA256': digest(runner.read_bytes()) if runner.is_file() else None,
              'entries': [], 'errors': [], 'runtimeVerified': False}
    # Resume only the same catalog/model/runner. Never overwrite an unrelated draft.
    if output.exists():
        previous = json.loads(output.read_text())
        for field in ['schemaVersion', 'engine', 'reviewStatus', 'catalogSHA256', 'manifestSHA256', 'runnerSHA256']:
            if previous.get(field) != report.get(field):
                raise ValueError(f'existing draft {field} differs; use a separate output for changed inputs')
        report = previous
    completed = {(entry['key'], entry['locale']) for entry in report['entries']}
    # Keep the catalog immutable, even on partial failures or interruption.
    atomic_json(output, report)
    if not manifest.is_file():
        report['errors'].append({'error': 'MADLAD400.manifest.json missing; no model inference attempted'})
        atomic_json(output, report)
        return 1
    jobs = []
    for key, entry in data.get('strings', {}).items():
        source = entry.get('localizations', {}).get('en', {}).get('stringUnit', {}).get('value') or key
        if not source.strip():
            continue
        if '\\(' in source or entry.get('localizations', {}).get('en', {}).get('variations'):
            report['errors'].append({'key': key, 'error': 'unexpanded Swift interpolation/plural variation needs actual Xcode extraction; not translated as literal text'})
            continue
        for locale in locales:
            if locale == 'en' or (key, locale) in completed:
                continue
            existing = entry.get('localizations', {}).get(locale, {}).get('stringUnit', {})
            if existing.get('value', '').strip():
                continue
            job = {'id': str(len(jobs)), 'source': source, 'locale': locale,
                   'protectedLiterals': FORMAT.findall(source)}
            jobs.append((key, job))
            if limit and len(jobs) >= limit:
                break
        if limit and len(jobs) >= limit:
            break
    atomic_json(output, report)
    # Sequential stdin/output keeps one loaded model and checkpoints every result.
    with subprocess.Popen([str(runner), str(resource_directory)], stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE, text=True) as process:
        try:
            for key, job in jobs:
                process.stdin.write(json.dumps(job, ensure_ascii=False) + '\n')
                process.stdin.flush()
                line = process.stdout.readline()
                if not line:
                    raise RuntimeError(f'native runner ended before result {job["id"]}')
                result = json.loads(line)
                if result.get('id') != job['id']:
                    raise RuntimeError('native runner result identity mismatch')
                if result.get('error') or not result.get('value', '').strip():
                    report['errors'].append({'key': key, 'locale': job['locale'], 'error': result.get('error') or 'empty output'})
                else:
                    report['entries'].append({'key': key, 'locale': job['locale'], 'source': job['source'],
                        'sourceSHA256': digest(job['source'].encode()), 'value': result['value'],
                        'reviewStatus': 'unreviewed-machine-draft'})
                atomic_json(output, report)
            process.stdin.close()
            if process.wait() != 0:
                raise RuntimeError('native runner failed')
        except BaseException as error:
            report['errors'].append({'error': f'native runner interrupted/failed: {type(error).__name__}: {error}'})
            atomic_json(output, report)
            process.terminate()
            process.wait()
            raise
    if catalog.read_bytes() != original:
        raise RuntimeError('source catalog changed independently during translation; drafts require reconciliation')
    # Successful output is a guarded machine draft, never a runtime/quality attestation.
    atomic_json(output, report)
    return 1 if report['errors'] else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-only', action='store_true')
    parser.add_argument('--swift', default='swiftc', help='Swift compiler executable')
    parser.add_argument('--native-llama-build', type=Path)
    parser.add_argument('--runner', type=Path, required=True)
    parser.add_argument('--catalog', type=Path)
    parser.add_argument('--resources', type=Path)
    parser.add_argument('--draft-output', type=Path)
    parser.add_argument('--locales', nargs='+')
    parser.add_argument('--limit', type=int)
    args = parser.parse_args()
    if args.build_only:
        if not args.native_llama_build:
            parser.error('--build-only requires --native-llama-build')
        build_runner(args.swift, args.native_llama_build.resolve(), args.runner.resolve())
        return 0
    if not all([args.catalog, args.resources, args.draft_output, args.locales]):
        parser.error('translation requires --catalog --resources --draft-output --locales')
    if args.locales and 'en' in args.locales:
        parser.error('the English source is not a translation target')
    if args.limit is not None and args.limit <= 0:
        parser.error('--limit must be positive')
    return translate_catalog(args.catalog, args.resources, args.runner.resolve(), args.draft_output, args.locales, args.limit)


if __name__ == '__main__':
    raise SystemExit(main())
