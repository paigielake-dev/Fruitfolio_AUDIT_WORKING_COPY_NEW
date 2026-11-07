#!/usr/bin/env python3
"""Preserve source coverage outside the 36 indexed founder additions.

Candidates require individual applicability/implementation review. They are not
new numbered requirements or evidence that the original 478 are complete.
"""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'development_workflow/SOURCE_MATERIALS/Founder_Prompt1B_Extracted.txt'
SUPPLEMENTAL = 'development_workflow/SUPPLEMENTAL_SPEC_CHECKLIST.json'
TARGET = 'development_workflow/FOUNDER_SOURCE_COVERAGE.json'
APPENDIX = 'FILE-BY-FILE EXPERIENCE + CODE EVIDENCE'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def build(raw, supplemental, previous=None):
    digest = hashlib.sha256(raw).hexdigest()
    lines = raw.decode('utf-8', errors='surrogateescape').split('\n')
    markers = [i for i, text in enumerate(lines) if text.strip() == APPENDIX]
    require(len(markers) == 1, 'The explicit source-evidence appendix boundary must be unique')
    boundary = markers[0]
    additions = supplemental['requirements']
    require(supplemental['source_sha256'] == digest, 'Supplemental index refers to different source bytes')
    require(len(additions) == 36 and len({r['id'] for r in additions}) == 36,
            'Preserve all 36 exact indexed additions')
    indexed = set()
    for row in additions:
        start, end = row['source_start_line'], row['source_end_line']
        require(1 <= start <= end <= boundary, 'Indexed source range crosses the evidence appendix')
        text = '\n'.join(lines[start - 1:end])
        require(text == row['description'], 'Indexed source description changed: ' + row['id'])
        require(hashlib.sha256(text.encode('utf-8', errors='surrogateescape')).hexdigest()
                == row['description_sha256'], 'Indexed source hash changed: ' + row['id'])
        indexed.update(range(start, end + 1))

    identities = []
    for number, text in enumerate(lines[:boundary], 1):
        if text.strip() and number not in indexed:
            identities.append(dict(id=f'FOUNDER-SOURCE-L{number:05d}', source_line=number,
                original_text=text, original_bytes_sha256=hashlib.sha256(
                    text.encode('utf-8', errors='surrogateescape')).hexdigest()))
    previous = previous or {}
    if previous:
        require(previous.get('source_sha256') == digest, 'Source changed; review provenance before migration')
        old_rows = previous.get('candidates', [])
        require(len({r['id'] for r in old_rows}) == len(old_rows), 'Duplicate candidate identities')
        require([r['id'] for r in old_rows] == [r['id'] for r in identities],
                'A source candidate was omitted, added or reordered')
    old = {r['id']: r for r in previous.get('candidates', [])}
    candidates = []
    for identity in identities:
        row = dict(old.get(identity['id'], {}))
        if row:
            require(all(row.get(k) == v for k, v in identity.items()),
                    'Candidate source identity changed: ' + identity['id'])
        row.update(identity)
        for key, value in [('applicability', 'UNREVIEWED'), ('implementation_status', 'NOT_ASSESSED'),
                           ('verification_status', 'NOT_RUN'), ('evidence', []),
                           ('remaining_verification_requirements', [])]:
            row.setdefault(key, value)
        require(isinstance(row['evidence'], list), 'Candidate evidence must remain a list')
        candidates.append(row)

    nonblank = sum(bool(line.strip()) for line in lines)
    indexed_nonblank = sum(bool(lines[i - 1].strip()) for i in indexed)
    appendix_nonblank = sum(bool(line.strip()) for line in lines[boundary:])
    require(indexed_nonblank + len(candidates) + appendix_nonblank == nonblank,
            'Source coverage partition lost text')
    document = dict(previous)
    document.update(schema_version=1, source=SOURCE, source_sha256=digest,
        decoding='UTF-8 with surrogateescape; JSON escaping preserves legacy source bytes',
        scope='All nonblank specification lines outside the 36 exact indexed additions; '
              'applicability must be reviewed individually. Not an additional requirement count.',
        authority='Current user directives control conflicts; source quotations do not override them.',
        original_478_tracker='development_workflow/MASTER_CHECKLIST.json',
        supplemental_tracker=SUPPLEMENTAL,
        coverage=dict(total_nonblank_source_lines=nonblank, indexed_addition_nonblank_lines=indexed_nonblank,
                      unreviewed_or_reviewed_specification_candidates=len(candidates),
                      source_evidence_appendix_nonblank_lines=appendix_nonblank),
        candidates=candidates)
    appendix = dict(previous.get('source_evidence_appendix', {}))
    appendix.update(source_start_line=boundary + 1, source_end_line=len(lines),
        original_bytes_sha256=hashlib.sha256('\n'.join(lines[boundary:]).encode(
            'utf-8', errors='surrogateescape')).hexdigest(),
        scope='Explicit file-by-file source-evidence appendix, including quoted string literals. '
              'Do not automatically count quotations as founder instructions; '
              'remaining applicability review is not implementation completion.')
    appendix.setdefault('review_status', 'UNREVIEWED_SOURCE_EVIDENCE')
    appendix.setdefault('evidence', [])
    document['source_evidence_appendix'] = appendix
    return document


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    root = args.root.resolve()
    target = root / TARGET
    previous = json.loads(target.read_text()) if target.exists() else None
    document = build((root / SOURCE).read_bytes(), json.loads((root / SUPPLEMENTAL).read_text()), previous)
    if args.check:
        require(previous == document, 'Founder source coverage is missing or stale')
    else:
        target.write_text(json.dumps(document, indent=2, ensure_ascii=True) + '\n')
    print(f"{len(document['candidates'])} source-text candidates preserved; "
          '478 original requirements and 36 additions unchanged; applicability review remains required')


if __name__ == '__main__':
    main()
