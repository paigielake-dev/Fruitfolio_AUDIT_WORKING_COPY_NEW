"""Bounded source invariant; this does not execute SwiftUI or Apple APIs."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class UIQAPreferenceIsolationTests(unittest.TestCase):
    def test_every_shell_qa_entrypoint_uses_the_disposable_preference_route(self):
        shell = (ROOT / 'Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift').read_text()
        content = (ROOT / 'Fruitfolio/Fruitfolio/ContentView.swift').read_text()
        entrypoints = set(re.findall(r'\.contains\("(-fruitfolio[^"\n]+QA)"\)', shell))
        declared = set(re.findall(r'"(-fruitfolio[^"\n]+QA)"', content))
        self.assertGreater(len(entrypoints), 5, 'Source inspection must find real entrypoints')
        self.assertFalse(entrypoints - declared, f'QA routes missing private shell preferences: {entrypoints - declared}')
        self.assertIn('Prompt03SkeletonView(defaults: defaults)', content)
        # Actual suite creation/cleanup is covered by Foundation Swift tests.
        self.assertIn('let defaults = regressionPreferences.defaults', content)
        self.assertIn('UI regression environment could not be created.', content)
