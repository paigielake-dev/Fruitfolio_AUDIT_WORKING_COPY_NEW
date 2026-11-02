import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('report', Path(__file__).parents[1] / 'report_xctest_executions.py')
report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(report)

class ExecutionReportTests(unittest.TestCase):
    def test_restart_summary_cannot_erase_failed_execution(self):
        result = report.summarize("""Test Case '-[Smoke background]' started.
Test Case '-[Smoke background]' failed (68.296 seconds).
Restarting after unexpected exit
Test Case '-[Smoke normal]' started.
Test Case '-[Smoke normal]' passed (29.680 seconds).
Test Case '-[Smoke reduced]' started.
Test Case '-[Smoke reduced]' passed (25.487 seconds).
Test Case '-[Smoke skip]' started.
Test Case '-[Smoke skip]' passed (13.231 seconds).
Executed 3 tests, with 0 failures
""")
        self.assertEqual(result['counts'], {'PASS': 3, 'FAIL': 1, 'SKIPPED': 0, 'NOT VERIFIED': 0})
        self.assertFalse(result['cleanExecution'])

    def test_retry_preserves_both_executions(self):
        result = report.summarize("""Test Case 'repeat' started.
Test Case 'repeat' failed (1.0 seconds).
Test Case 'repeat' started.
Test Case 'repeat' passed (2.0 seconds).
""")
        self.assertEqual(result['executionCount'], 2)
        self.assertEqual(result['counts']['FAIL'], 1)

    def test_unfinished_and_skip_never_become_pass(self):
        result = report.summarize("""Test Case 'pending' started.
Test Case 'hardware' started.
Test Case 'hardware' skipped (0.01 seconds).
""")
        self.assertEqual(result['counts']['PASS'], 0)
        self.assertEqual(result['counts']['NOT VERIFIED'], 1)
        self.assertEqual(result['counts']['SKIPPED'], 1)
        self.assertFalse(result['cleanExecution'])

    def test_empty_log_is_not_success(self):
        self.assertFalse(report.summarize('Executed 0 tests')['cleanExecution'])

if __name__ == '__main__':
    unittest.main()
