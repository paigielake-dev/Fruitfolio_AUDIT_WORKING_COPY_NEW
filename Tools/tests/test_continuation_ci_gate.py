import importlib.util
from datetime import datetime,timezone
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('planner',Path(__file__).resolve().parents[1]/'sprint_ci_plan.py')
planner=importlib.util.module_from_spec(spec);spec.loader.exec_module(planner)
class HistoricalDeadlineTests(unittest.TestCase):
    def test_expired_sprint_tag_never_resets_historical_deadline(self):
        deadline=datetime(2026,11,2,20,15,tzinfo=timezone.utc);now=datetime(2026,11,4,tzinfo=timezone.utc)
        self.assertFalse(planner.should_run_verification('[sprint-verify]',now,deadline))
        self.assertFalse(planner.should_run_verification('ordinary source commit',now,deadline))
    def test_separately_authorized_continuation_tag_runs_without_rewriting_clock(self):
        deadline=datetime(2026,11,2,20,15,tzinfo=timezone.utc);now=datetime(2026,11,4,tzinfo=timezone.utc)
        self.assertTrue(planner.should_run_verification('[continuation-verify]',now,deadline))
        self.assertEqual(deadline,datetime(2026,11,2,20,15,tzinfo=timezone.utc))
