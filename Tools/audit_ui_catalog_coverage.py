#!/usr/bin/env python3
"""Report declared UI catalog coverage; never infer translation/runtime acceptance."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re


def units(value):
    if not isinstance(value, dict):
        return []
    result = []
    if isinstance(value.get('stringUnit'), dict):
        unit = value['stringUnit']
        if isinstance(unit.get('value'), str) and unit['value'].strip():
            result.append(unit)
    for key, nested in value.items():
        if key != 'stringUnit' and isinstance(nested, dict):
            result.extend(units(nested))
    return result


def summarize(catalog, languages):
    strings = catalog['strings']
    source = catalog.get('sourceLanguage', 'en')
    rows = []
    for language in languages:
        entries = 0
        different = 0
        states = Counter()
        for key, record in strings.items():
            localizations = record.get('localizations', {})
            values = units(localizations.get(language, {}))
            if not values:
                continue
            entries += 1
            states.update(unit.get('state', 'unspecified') for unit in values)
            original = [unit['value'] for unit in units(localizations.get(source, {}))] or [key]
            if [unit['value'] for unit in values] != original:
                different += 1
        rows.append({'language': language, 'declaredNonemptyEntries': entries,
                     'entriesDifferentFromSource': different,
                     'missingExplicitEntries': len(strings) - entries,
                     'declaredUnitStates': dict(states),
                     'acceptanceStatus': 'NOT VERIFIED',
                     'note': 'Catalog metadata only; not compilation, native review, screen coverage or scientific translation approval.'})
    return {'sourceLanguage': source, 'keyCount': len(strings), 'languageCount': len(languages),
            'languages': rows, 'MADLADInference': 'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    root = args.root
    catalog_path = root / 'Fruitfolio/Localizable.xcstrings'
    data = catalog_path.read_bytes()
    declaration = (root / 'Fruitfolio/Core/AppArchitecture/SettingsStore.swift').read_text().split('    var id:', 1)[0]
    languages = re.findall(r'^\s*case\s+\w+\s*=\s*"([^"]+)"', declaration, re.MULTILINE)
    if not languages or len(languages) != len(set(languages)):
        raise SystemExit('Language declaration is missing or ambiguous; no coverage report produced.')
    result = summarize(json.loads(data), languages)
    result.update({'recordedAtUTC': datetime.now(timezone.utc).isoformat(),
                   'catalogSHA256': hashlib.sha256(data).hexdigest(),
                   'scope': 'Declared resource coverage only. Every language remains NOT VERIFIED until actual UI/native-language acceptance.'})
    output = args.output or root / 'Fruitfolio_Verification_Evidence/FiveHourSprint/Phase6Localization/CatalogCoverage.json'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(f'{result["keyCount"]} UI keys; {result["languageCount"]} individually declared language choices. Resource counts saved; no language promoted to PASS.')


if __name__ == '__main__':
    main()
