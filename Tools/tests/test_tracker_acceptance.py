import copy
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('reconcile_five_hour_tracker', ROOT / 'Tools/reconcile_five_hour_tracker.py')
tracker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tracker)


def intake():
    return {'requirements': [{'requirementID': f'FF1B-{n:03}', 'implementationStatus': 'NOT VERIFIED',
                              'originalBreakdownItem': 'Synthetic fixture criterion', 'relevantSourceFiles': [],
                              'remainingIssues': []} for n in range(1, 479)]}


class AcceptanceAccountingSafetyTests(unittest.TestCase):
    def testSourceOnlyChangesNeverPromoteARequirementToPass(self):
        doc = intake()
        doc['requirements'][0]['implementationStatus'] = 'PASS'
        ledger = {'requirements': [{'requirementID': 'FF1B-002', 'status': tracker.PENDING,
                                    'implementationFiles': ['Exists.swift'], 'changes': 'Added source, not executed'}]}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); (root / 'Exists.swift').write_text('import Foundation\n')
            result = tracker.reconcile(doc, [('ledger.json', ledger)], root, {})
        self.assertEqual(result['requirements'][0]['implementationStatus'], tracker.PENDING)
        self.assertEqual(result['requirements'][1]['implementationStatus'], tracker.PENDING)
        self.assertEqual(result['summary'].get('PASS', 0), 0)

    def testDeferredInferenceDoesNotExcludeFeasibleInterfaceArchitecture(self):
        with tempfile.TemporaryDirectory() as directory:
            result = tracker.reconcile(intake(), [], Path(directory), {})
        rows = {r['requirementID']: r for r in result['requirements']}
        self.assertEqual(rows['FF1B-441']['implementationStatus'], tracker.EXCLUDED_STATUS)
        self.assertNotEqual(rows['FF1B-391']['implementationStatus'], tracker.EXCLUDED_STATUS)
        self.assertNotEqual(rows['FF1B-398']['implementationStatus'], tracker.EXCLUDED_STATUS)
        self.assertEqual(len(rows), 478)

    def testHistoricalFailureCannotDisappearIntoANewPassAndNarrowPassNeedsProof(self):
        doc = intake(); doc['requirements'][467]['implementationStatus'] = 'FAIL'
        doc['requirements'][243]['implementationStatus'] = 'PASS'
        with tempfile.TemporaryDirectory() as directory:
            result = tracker.reconcile(copy.deepcopy(doc), [], Path(directory), {})
        self.assertEqual(result['requirements'][467]['implementationStatus'], 'NOT VERIFIED')
        self.assertEqual(result['requirements'][467]['lastKnownFailedAcceptance']['status'], 'FAIL')
        self.assertEqual(result['requirements'][243]['implementationStatus'], tracker.PENDING)


if __name__ == '__main__':
    unittest.main()
