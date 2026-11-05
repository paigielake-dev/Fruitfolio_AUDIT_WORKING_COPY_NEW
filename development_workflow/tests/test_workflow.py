import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]

class WorkflowIntegrityTests(unittest.TestCase):
    def test_all_original_requirements_and_labels_preserved(self):
        data = json.loads((ROOT / 'MASTER_CHECKLIST.json').read_text())
        source = ROOT / 'SOURCE_MATERIALS/Prompt1B_Checklist.txt'
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), data['source_sha256'])
        text = source.read_text()
        text = text[text.index('Part 1 —'):text.index('Implementation order')]
        headings = {'Universal blur system', 'Universal button system', 'Universal popup layout system',
                    'Universal decorative artwork layout system', 'Universal semantic text stylization',
                    'Performance and responsiveness'}
        expected = [(m[1], m[2]) for line in text.splitlines()
                    if (m := re.match(r'(\d+)\. (.+)', line)) and m[2] not in headings]
        actual = [(r['original_requirement_id'], r['description']) for r in data['requirements']]
        self.assertEqual(len(expected), 478)
        self.assertEqual(actual, expected)
        self.assertEqual([r['sequence'] for r in data['requirements']], list(range(1, 479)))

    def test_notebook_geometry_matches_actual_bundled_png(self):
        import struct
        repo = ROOT.parent
        asset = next((repo / 'Fruitfolio/Assets.xcassets').rglob('popup_notebook_paper.png'))
        dimensions = struct.unpack('>II', asset.read_bytes()[16:24])
        source = (repo / 'Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift').read_text()
        declared = re.search(r'notebookPixelSize = CGSize\(width: (\d+), height: (\d+)\)', source)
        self.assertIsNotNone(declared)
        self.assertEqual(tuple(map(int, declared.groups())), dimensions)

    def test_statuses_do_not_claim_unexecuted_ios_verification(self):
        rows = json.loads((ROOT / 'MASTER_CHECKLIST.json').read_text())['requirements']
        for row in rows:
            self.assertIn(row['implementation_status'], {'NOT_STARTED', 'IN_PROGRESS', 'IMPLEMENTED', 'BLOCKED', 'DEFERRED'})
            self.assertIn(row['verification_status'], {'NOT_RUN', 'SOURCE_REVIEWED', 'TEST_PASSED', 'TEST_FAILED', 'MANUAL_VERIFICATION_REQUIRED'})
            if row['verification_status'] == 'TEST_PASSED':
                self.assertTrue(row['related_tests'])
                self.assertTrue(row['evidence_of_implementation'])
        checkpoint = json.loads((ROOT / 'CURRENT_CHECKPOINT.json').read_text())
        self.assertEqual(set(checkpoint['completed_requirements']) | set(checkpoint['remaining_requirements']), set(range(1, 479)))
        self.assertFalse(set(checkpoint['completed_requirements']) & set(checkpoint['remaining_requirements']))

if __name__ == '__main__':
    unittest.main()
