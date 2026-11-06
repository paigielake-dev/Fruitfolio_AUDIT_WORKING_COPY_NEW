"""Execute the actual SwiftSyntax checker; not an Apple UI acceptance test."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class SharedConfirmationCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        compiler = os.environ.get('FRUITFOLIO_SWIFTC') or shutil.which('swiftc')
        if not compiler:
            raise unittest.SkipTest('Swift compiler with SwiftSyntax is unavailable')
        host = Path(compiler).resolve().parent.parent / 'lib/swift/host'
        if not (host / 'SwiftParser.swiftmodule').is_dir():
            raise unittest.SkipTest('Toolchain host SwiftParser is unavailable')
        cls.work = tempfile.TemporaryDirectory(prefix='fruitfolio-dialog-tool-')
        cls.addClassCleanup(cls.work.cleanup)
        cls.binary = Path(cls.work.name) / 'shared-confirmations'
        result = subprocess.run([compiler, '-parse-as-library', '-module-cache-path', str(Path(cls.work.name) / 'cache'),
                                 '-I', str(host), '-L', str(host), '-lSwiftSyntax', '-lSwiftParser',
                                 '-Xlinker', '-rpath', '-Xlinker', str(host),
                                 str(ROOT / 'Tools/check_shared_confirmation_coverage.swift'), '-o', str(cls.binary)],
                                capture_output=True, text=True)
        if result.returncode:
            raise AssertionError(result.stderr)

    def test_real_syntax_calls_are_found_but_comments_strings_and_options_are_not(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'sample.swift'
            path.write_text('''// view.alert("example")
let prose = "view.confirmationDialog(quoted)"
let option = AuthorizationOptions.alert
view.alert("message", isPresented: $flag) { Button("ok") {} }
view
 .confirmationDialog("confirm", isPresented: $flag) { Button("cancel") {} }
''')
            before = path.read_bytes()
            result = subprocess.run([str(self.binary), str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stderr)
            findings = json.loads(result.stdout)
            self.assertEqual([row['method'] for row in findings], ['alert', 'confirmationDialog'])
            self.assertEqual([row['line'] for row in findings], [4, 6])
            self.assertEqual(path.read_bytes(), before)

    def test_parse_or_read_failure_never_reports_a_clean_repository(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'broken.swift'
            path.write_text('struct Broken {')
            result = subprocess.run([str(self.binary), str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(result.stdout, '')
            result = subprocess.run([str(self.binary), str(path.with_name('missing.swift'))], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(result.stdout, '')

    def test_app_sources_use_shared_app_owned_confirmations(self):
        paths = sorted((ROOT / 'Fruitfolio').rglob('*.swift'))
        self.assertGreater(len(paths), 100)
        result = subprocess.run([str(self.binary), *map(str, paths)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(result.stdout), [])
