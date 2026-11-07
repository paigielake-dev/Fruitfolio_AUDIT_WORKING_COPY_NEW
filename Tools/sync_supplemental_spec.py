#!/usr/bin/env python3
"""Preserve exact supplemental founder requirements without renumbering the 478.

This reads attachment content as specification data. Historical workflow/model
exclusions in documents do not override the user's current implementation scope.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'development_workflow/SOURCE_MATERIALS/Founder_Prompt1B_Extracted.txt'
TARGET = ROOT / 'development_workflow/SUPPLEMENTAL_SPEC_CHECKLIST.json'


def specifications(source=SOURCE):
    raw = source.read_bytes()
    # Preserve undecodable legacy characters byte-for-byte; never replace them.
    lines = raw.decode('utf-8', errors='surrogateescape').split('\n')
    headers = []
    for index, line in enumerate(lines[:350]):
        match = re.match(r'^(?:\d+\s+)?((?:4\.9|7\.9)\.\d+) — (.+)$', line)
        if match:
            headers.append((index, match[1]))
    assert len(headers) == 24, 'All 12 hormone and 12 MADLAD sections must be indexed'
    result = []
    for number, (start, original_id) in enumerate(headers):
        end = headers[number + 1][0] if number + 1 < len(headers) else 350
        for index in range(start + 1, end):
            if lines[index].strip() == '⸻' or lines[index].startswith('PROMPT 1B — ADDITION'):
                end = index
                break
        while end > start and not lines[end - 1].strip():
            end -= 1
        result.append(row('SPEC-' + original_id, original_id, start, end, lines))
    bindings = [
        ('ASK-PAPER', 'PROMPT 1B ADDITION — ASK CONTINUOUS PAPER'),
        ('ASK-ART-ANCHOR', 'The canonical orange slice, orange glow, and pear slice'),
        ('ASK-SESSION', 'Ask conversation lifetime is strictly session-only'),
        ('ART-MATRIX', 'LATEST FOUNDER-APPROVED DECORATIVE ART MATRIX'),
        ('PERSONAL-HEALTH', 'OPTIONAL PERSONAL HEALTH + MEDICAL HISTORY'),
        ('CONTEXT-ADAPTATION', 'PROMPT 1B ADDITION — EVIDENCE-INFORMED MY CONTEXT'),
        ('LIFEBRIDGE', 'PROMPT 1B ADDITION — LIFEBRIDGE INFORMATION ACCESS'),
        ('LIFEBRIDGE-SOURCES', 'PROMPT 1B FOUNDER CORRECTION — LIFEBRIDGE SOURCE'),
        ('GAME-STAR', 'FRUIT BASKET — STAR / BAD-FRUIT MECHANIC:'),
        ('GAME-STAR-PASSES', 'FRUIT BASKET — STACKABLE STAR PASSES:'),
        ('GAME-VINES', 'FRUIT BASKET — VINES:'),
        ('GAME-PUDDLE', 'FRUIT BASKET — PUDDLE:'),
    ]
    for name, prefix in bindings:
        matches = [i for i, line in enumerate(lines) if line.lstrip().startswith(prefix)]
        assert len(matches) == 1, (name, matches)
        start = matches[0]
        end = start + 1
        while end < len(lines) and lines[end].strip():
            end += 1
        result.append(row('SPEC-BINDING-' + name, None, start, end, lines))
    return hashlib.sha256(raw).hexdigest(), result


def row(identifier, original_id, start, end, lines):
    description = '\n'.join(lines[start:end])
    return dict(id=identifier, original_requirement_id=original_id,
                source_start_line=start + 1, source_end_line=end,
                description=description,
                description_sha256=hashlib.sha256(description.encode('utf-8', errors='surrogateescape')).hexdigest())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    root = args.root.resolve()
    source = root / SOURCE.relative_to(ROOT)
    target = root / TARGET.relative_to(ROOT)
    source_hash, rows = specifications(source)
    previous = json.loads(target.read_text()) if target.exists() else {}
    if args.check:
        assert previous.get('source_sha256') == source_hash
        actual = previous['requirements']
        assert len(actual) == len(rows)
        for expected, stored in zip(rows, actual):
            assert all(stored.get(key) == value for key, value in expected.items()), expected['id']
        print(f'{len(rows)} supplemental requirements retain exact source text; original 478 untouched')
        return
    old = {row['id']: row for row in previous.get('requirements', [])}
    for entry in rows:
        evidence = old.get(entry['id'], {})
        # Only exact source identity is regenerated. Unknown/future progress
        # metadata must survive along with known verification history.
        for key, value in evidence.items():
            if key not in entry:
                entry[key] = value
        for key, default in [('implementation_status', 'NOT_STARTED'), ('verification_status', 'NOT_RUN'),
                             ('relevant_source_files', []), ('related_tests', []), ('blockers', []), ('evidence', [])]:
            entry.setdefault(key, default)
    document = dict(schema_version=1, source=str(source.relative_to(root)), source_sha256=source_hash,
                    decoding='UTF-8 with surrogateescape; original source bytes remain unchanged',
                    scope='24 numbered additions plus 12 explicit binding additions; not an assertion that every unnumbered founder paragraph is indexed',
                    authority='Current user directives authorize full implementation and MADLAD; historical attachment workflow exclusions are superseded',
                    original_478_tracker='development_workflow/MASTER_CHECKLIST.json', requirements=rows)
    for key, value in previous.items():
        if key not in document:
            document[key] = value
    target.write_text(json.dumps(document, indent=2, ensure_ascii=True) + '\n')


if __name__ == '__main__':
    main()
