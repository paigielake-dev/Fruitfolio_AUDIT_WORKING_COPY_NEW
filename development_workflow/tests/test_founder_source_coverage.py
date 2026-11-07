import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('founder_coverage', ROOT / 'Tools/sync_founder_source_coverage.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FounderSourceCoverageTests(unittest.TestCase):
    def setUp(self):
        self.raw = (ROOT / MODULE.SOURCE).read_bytes()
        self.index = json.loads((ROOT / MODULE.SUPPLEMENTAL).read_text())

    def test_every_nonblank_source_line_is_accounted_without_promoting_candidate_text(self):
        document = MODULE.build(self.raw, self.index)
        counts = document['coverage']
        self.assertEqual(counts['total_nonblank_source_lines'],
                         counts['indexed_addition_nonblank_lines'] +
                         counts['unreviewed_or_reviewed_specification_candidates'] +
                         counts['source_evidence_appendix_nonblank_lines'])
        self.assertTrue(document['candidates'])
        self.assertTrue(all(r['applicability'] == 'UNREVIEWED' and
                            r['implementation_status'] == 'NOT_ASSESSED' for r in document['candidates']))
        self.assertEqual(document['source_evidence_appendix']['review_status'], 'UNREVIEWED_SOURCE_EVIDENCE')
        annotations = document['source_evidence_appendix']['instruction_annotations']
        self.assertEqual([r['source_start_line'] for r in annotations], [2535, 10783, 10850])
        self.assertEqual(annotations[1]['source_end_line'], 10785)
        self.assertIn('little handbooks', annotations[1]['original_text'])
        self.assertTrue(all(r['applicability'] == 'UNREVIEWED' and r['implementation_status'] == 'NOT_ASSESSED'
                            and r['verification_status'] == 'NOT_RUN' for r in annotations))

    def test_legacy_invalid_utf8_roundtrips_exact_bytes_instead_of_replacement(self):
        first = MODULE.build(self.raw, self.index)['candidates'][0]
        lines = self.raw.split(b'\n')
        lines[first['source_line'] - 1] += b'\xff'
        changed = b'\n'.join(lines)
        self.index['source_sha256'] = hashlib.sha256(changed).hexdigest()
        document = MODULE.build(changed, self.index)
        decoded = json.loads(json.dumps(document, ensure_ascii=True))
        row = decoded['candidates'][0]
        self.assertEqual(row['original_text'].encode('utf-8', errors='surrogateescape'),
                         lines[first['source_line'] - 1])

    def test_review_evidence_and_future_metadata_survive_regeneration(self):
        previous = MODULE.build(self.raw, self.index)
        previous['future_review_notes'] = {'preserve': True}
        previous['candidates'][0].update(applicability='REFERENCE_ONLY', evidence=[{'review': 'fixture'}])
        previous['source_evidence_appendix']['instruction_annotations'][0].update(
            applicability='APPLICABLE', implementation_status='IN_PROGRESS', evidence=[{'review': 'annotation fixture'}])
        self.assertEqual(MODULE.build(self.raw, self.index, previous), previous)
        omitted = copy.deepcopy(previous)
        omitted['candidates'].pop()
        with self.assertRaisesRegex(ValueError, 'omitted'):
            MODULE.build(self.raw, self.index, omitted)

    def test_tampered_source_identity_and_mismatched_index_are_rejected(self):
        previous = MODULE.build(self.raw, self.index)
        previous['candidates'][0]['original_text'] += 'changed'
        with self.assertRaisesRegex(ValueError, 'identity changed'):
            MODULE.build(self.raw, self.index, previous)
        clean = MODULE.build(self.raw, self.index)
        clean['source_evidence_appendix']['instruction_annotations'][0]['original_text'] += 'changed'
        with self.assertRaisesRegex(ValueError, 'Appendix annotation source identity'):
            MODULE.build(self.raw, self.index, clean)
        omitted = MODULE.build(self.raw, self.index)
        omitted['source_evidence_appendix']['instruction_annotations'].pop()
        with self.assertRaisesRegex(ValueError, 'annotation was omitted'):
            MODULE.build(self.raw, self.index, omitted)
        self.index['requirements'][0]['description'] += 'changed'
        with self.assertRaisesRegex(ValueError, 'description changed'):
            MODULE.build(self.raw, self.index)


if __name__ == '__main__':
    unittest.main()
