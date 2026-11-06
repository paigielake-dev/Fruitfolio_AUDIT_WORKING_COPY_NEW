"""Draft orchestration tests only; the fixture executable is NOT model inference."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('madlad_drafts', ROOT / 'Tools/translate_catalog_with_madlad.py')
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)


class MADLADCatalogDraftTests(unittest.TestCase):
    def fixture(self, root):
        catalog = root / 'Localizable.xcstrings'
        catalog.write_text(json.dumps({'strings': {
            'value %@': {'localizations': {'es': {'stringUnit': {'value': 'existing reviewed string', 'state': 'translated'}}}},
            'missing %.2f': {},
            'literal \\(doNotEvaluate)': {},
        }}))
        resources = root / 'resources'
        resources.mkdir()
        (resources / 'MADLAD400.manifest.json').write_text('{}')
        runner = root / 'fixture-runner'
        runner.write_text('#!' + sys.executable + '\n' + '''import json, sys
for line in sys.stdin:
    job = json.loads(line)
    print(json.dumps({'id': job['id'], 'value': 'fixture only ' + job['source']}), flush=True)
''')
        runner.chmod(0o755)
        return catalog, resources, runner, root / 'draft.json'

    def testDraftsNeverModifyCatalogOrApproveUnreviewedOutput(self):
        with tempfile.TemporaryDirectory() as folder:
            catalog, resources, runner, output = self.fixture(Path(folder))
            original = catalog.read_bytes()
            self.assertEqual(tool.translate_catalog(catalog, resources, runner, output, ['es']), 1)
            self.assertEqual(catalog.read_bytes(), original)
            result = json.loads(output.read_text())
            self.assertFalse(result['runtimeVerified'])
            self.assertEqual(result['reviewStatus'], 'unreviewed-machine-draft')
            self.assertEqual([entry['key'] for entry in result['entries']], ['missing %.2f'])
            self.assertEqual(result['entries'][0]['sourceSHA256'], tool.digest(b'missing %.2f'))
            self.assertEqual(result['entries'][0]['reviewStatus'], 'unreviewed-machine-draft')
            self.assertEqual(result['catalogSHA256'], tool.digest(original))
            self.assertIn('interpolation', result['errors'][0]['error'])

    def testMatchingDraftResumesWithoutDuplicatingResultsAndChangedInputsCannotOverwriteIt(self):
        with tempfile.TemporaryDirectory() as folder:
            catalog, resources, runner, output = self.fixture(Path(folder))
            tool.translate_catalog(catalog, resources, runner, output, ['es'])
            tool.translate_catalog(catalog, resources, runner, output, ['es'])
            self.assertEqual(len(json.loads(output.read_text())['entries']), 1)
            saved = output.read_bytes()
            catalog.write_text('{"strings": {"changed source": {}}}')
            with self.assertRaisesRegex(ValueError, 'catalogSHA256 differs'):
                tool.translate_catalog(catalog, resources, runner, output, ['es'])
            self.assertEqual(output.read_bytes(), saved)

    def testMissingResourcesRecordExactBlockerWithoutStartingRunner(self):
        with tempfile.TemporaryDirectory() as folder:
            catalog, resources, runner, output = self.fixture(Path(folder))
            (resources / 'MADLAD400.manifest.json').unlink()
            self.assertEqual(tool.translate_catalog(catalog, resources, Path('/does-not-exist'), output, ['es']), 1)
            report = json.loads(output.read_text())
            self.assertEqual(report['entries'], [])
            self.assertIn('no model inference attempted', report['errors'][0]['error'])

    def testCannotReplaceSourceCatalogWithDraftOrIgnoreMismatchedResponse(self):
        with tempfile.TemporaryDirectory() as folder:
            catalog, resources, runner, output = self.fixture(Path(folder))
            original = catalog.read_bytes()
            with self.assertRaises(ValueError):
                tool.translate_catalog(catalog, resources, runner, catalog, ['es'])
            runner.write_text('#!' + sys.executable + '\nprint(\'{"id":"wrong", "value":"invalid"}\', flush=True)\n')
            with self.assertRaisesRegex(RuntimeError, 'identity mismatch'):
                tool.translate_catalog(catalog, resources, runner, output, ['es'], limit=1)
            self.assertEqual(catalog.read_bytes(), original)
            self.assertEqual(json.loads(output.read_text())['entries'], [])

    def testCompleteFormatSpecifiersAreProtectedAsOneLiteral(self):
        self.assertEqual(tool.FORMAT.findall('value %1$@; %.2f; %lld; %%'), ['%1$@', '%.2f', '%lld', '%%'])

    def testLegacyQwenAutoApprovalOptionsFailBeforeAnyModelExecution(self):
        result = subprocess.run([sys.executable, str(ROOT / 'Tools/translate_catalog_with_llama.py'),
                                 '--model', '/absent/qwen.gguf', '--overwrite'], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('--runner', result.stderr)


if __name__ == '__main__':
    unittest.main()
